"""
auto_retrain.py
---------------
Decides WHEN retraining happens and runs it off the request thread.

Two triggers:
  1. Threshold trigger  – after new confirmed samples are submitted, if the
     number of not-yet-used samples reaches RETRAIN_THRESHOLD, a retrain is
     launched in a background thread.
  2. Scheduled trigger  – an APScheduler job re-checks every
     RETRAIN_INTERVAL_HOURS and retrains if any new samples exist.
"""
import threading
import logging

log = logging.getLogger('baobab.auto_retrain')

_lock = threading.Lock()
_running = False


def _run(app, config, db, predictor):
    global _running
    with app.app_context():
        try:
            log.info('Automatic retraining triggered, but trainer.py has been moved to notebooks. Please retrain manually using notebooks/train_notebook.ipynb.')
            results = {'status': 'manual_retrain_required'}
            log.info('Automatic retraining finished: %s', results)
        except Exception as e:  # never let a retrain crash the server
            log.exception('Retraining failed: %s', e)
        finally:
            with _lock:
                globals()['_running'] = False


def trigger_if_needed(app, config, db, predictor, force=False):
    """Launch a background retrain if the threshold is met (or forced)."""
    global _running
    from database.models import TrainingSample
    pending = TrainingSample.query.filter_by(used_for_training=False).count()
    if not force and pending < config.RETRAIN_THRESHOLD:
        return {'triggered': False, 'pending': pending,
                'threshold': config.RETRAIN_THRESHOLD}
    with _lock:
        if _running:
            return {'triggered': False, 'reason': 'already_running', 'pending': pending}
        globals()['_running'] = True
    threading.Thread(target=_run, args=(app, config, db, predictor), daemon=True).start()
    return {'triggered': True, 'pending': pending}


def init_scheduler(app, config, db, predictor):
    """Optional periodic retrain check (requires APScheduler)."""
    if config.RETRAIN_INTERVAL_HOURS <= 0:
        return None
    try:
        from apscheduler.schedulers.background import BackgroundScheduler
    except Exception:
        log.warning('APScheduler not installed; scheduled retraining disabled.')
        return None

    sched = BackgroundScheduler(daemon=True)
    sched.add_job(lambda: trigger_if_needed(app, config, db, predictor, force=False),
                  'interval', hours=config.RETRAIN_INTERVAL_HOURS,
                  id='auto_retrain', replace_existing=True)
    sched.start()
    log.info('Scheduled retraining every %s h.', config.RETRAIN_INTERVAL_HOURS)
    return sched
