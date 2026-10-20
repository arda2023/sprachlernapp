"""One serial writer worker; HTTP and browser stay responsive."""
import threading
import uuid
from concurrent.futures import ThreadPoolExecutor
from .store import utc_now
from ..authoring_service import AuthoringError


class JobCancelled(Exception):pass


class JobContext:
    def __init__(self,manager,identifier,event):self.manager,self.id,self.event=manager,identifier,event

    def check_cancelled(self):
        if self.event.is_set():raise JobCancelled()

    def progress(self,message,processed=None,total=None):
        self.check_cancelled()
        job=self.manager.store.get('jobs',self.id)
        job.update(message=message,processed=processed,total=total)
        self.manager.store.put('jobs',self.id,job)


class Jobs:
    def __init__(self,store):
        self.store=store;self.executor=ThreadPoolExecutor(max_workers=1,thread_name_prefix='content-editor')
        self.events={};self.lock=threading.Lock()

    def submit(self,kind,function):
        identifier=str(uuid.uuid4());event=threading.Event()
        job={'job_id':identifier,'kind':kind,'state':'queued','message':'Wartet auf Verarbeitung.',
             'created_at':utc_now(),'processed':0,'total':None,'result':None}
        self.store.put('jobs',identifier,job)
        with self.lock:self.events[identifier]=event
        def run():
            current=self.store.get('jobs',identifier);current['state']='running';self.store.put('jobs',identifier,current)
            context=JobContext(self,identifier,event)
            try:
                context.check_cancelled();result=function(context)
                # Functions check cancellation before their atomic commit. Once
                # committed, return the truthful receipt even if Cancel raced.
                current=self.store.get('jobs',identifier);current.update(state='succeeded',result=result,message='Abgeschlossen.')
            except JobCancelled:
                current=self.store.get('jobs',identifier);current.update(state='cancelled',message='Abgebrochen. Kein gültiger Bestand ersetzt.')
            except Exception as e:
                current=self.store.get('jobs',identifier);current.update(state='failed',message=str(e),
                    error=e.finding() if isinstance(e,AuthoringError) else {'code':'JOB_FAILED','message':str(e)})
            current['finished_at']=utc_now();self.store.put('jobs',identifier,current)
            with self.lock:self.events.pop(identifier,None)
        self.executor.submit(run)
        return job

    def cancel(self,identifier):
        with self.lock:
            event=self.events.get(identifier)
            if event:
                event.set()
                job=self.store.get('jobs',identifier)
                if job['state'] in ('queued','running'):
                    job.update(state='cancelling',message='Abbruch angefordert. Laufenden Prüfschritt sicher abschließen …')
                    self.store.put('jobs',identifier,job)
        return self.store.get('jobs',identifier)

    def close(self):
        with self.lock:
            for event in self.events.values():event.set()
        self.executor.shutdown(wait=True,cancel_futures=False)
