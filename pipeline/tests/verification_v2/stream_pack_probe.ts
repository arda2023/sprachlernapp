// Experiment only: established tokenizer/assembler, not a new JSON parser.
// Assembly retains the complete value: streaming input is NOT bounded-memory proof.
import Parser from 'stream-json/Parser';
import Assembler from 'stream-json/Assembler';
import {Readable} from 'node:stream';
import {pipeline} from 'node:stream/promises';

export async function streamPack(
  bytes: ReadableStream<Uint8Array>, assemble = true,
  sample: (name:string)=>void = ()=>{},
): Promise<{value:any; tokens:number}> {
  const assembler = assemble ? new Assembler() : null;
  let tokens = 0;
  const parser = new Parser({streamKeys:false, streamStrings:false, streamNumbers:false});
  parser.on('data', (token:{name:string;value?:string}) => {
    tokens++;
    if (!assembler) return;
    // Library assignment to __proto__ would invoke Object.prototype's setter.
    // Predefine an own data property, preserving JSON.parse last-key-wins semantics.
    if(token.name==='keyValue' && token.value==='__proto__') {
      Object.defineProperty(assembler.current,'__proto__',{
        value:undefined,writable:true,enumerable:true,configurable:true,
      });
    }
    assembler.consume(token);
  });
  async function* text() {
    const decoder = new TextDecoder('utf-8',{fatal:true});
    for await(const chunk of bytes) yield decoder.decode(chunk,{stream:true});
    yield decoder.decode();
  }
  await pipeline(Readable.from(text()),parser);
  sample('stream-parsed');
  return {value:assembler?.current,tokens};
}
