import logging
import os


def init_logging():
    available_logging_levels = {'DEBUG', 'INFO', 'WARNING', 'ERROR', 'CRITICAL'}
    logging_level = os.getenv('LOG_LEVEL')

    if not logging_level:
        logging_level = 'DEBUG'

    if logging_level not in available_logging_levels:
        logging_level = 'DEBUG'

    default_logging_level = logging.DEBUG

    if logging_level == 'INFO':
        default_logging_level = logging.INFO
    elif logging_level == 'WARNING':
        default_logging_level = logging.WARNING
    elif logging_level == 'ERROR':
        default_logging_level = logging.ERROR
    elif logging_level == 'CRITICAL':
        default_logging_level = logging.CRITICAL

    logger = logging.getLogger("ntlm-auth")
    logger.setLevel(default_logging_level)

    console_handler = logging.StreamHandler()
    console_handler.setLevel(default_logging_level)

    formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s', datefmt="%Y-%m-%d %H:%M:%S")
    console_handler.setFormatter(formatter)

    logger.addHandler(console_handler)

    return logger


def debug(msg):
    logger.debug(msg)


def info(msg):
    logger.info(msg)


def warning(msg):
    logger.warning(msg)


def error(msg):
    logger.error(msg)


def critical(msg):
    logger.critical(msg)


logger = init_logging()
