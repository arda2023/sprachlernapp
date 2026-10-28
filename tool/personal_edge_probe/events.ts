const manager=new globalThis.EventManager();
for await(const event of manager)if(event)console.log(JSON.stringify(event));
