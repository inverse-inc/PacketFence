import logging


def init_logging():
    default_logging_level = logging.DEBUG

    logger = logging.getLogger("ntlm-auth")
    logger.setLevel(default_logging_level)

    console_handler = logging.StreamHandler()
    console_handler.setLevel(default_logging_level)

    # file_handler = logging.FileHandler("app.log")
    # file_handler.setLevel(default_logging_level)

    formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s', datefmt="%Y-%m-%d %H:%M:%S")
    console_handler.setFormatter(formatter)
    # file_handler.setFormatter(formatter)

    logger.addHandler(console_handler)
    # logger.addHandler(file_handler)

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
