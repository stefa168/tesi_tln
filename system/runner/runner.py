from pprint import pprint

from system.common.config import CompilerConfigV2


def main():
    config = CompilerConfigV2.load_from_file('../compiler/test_config v2.yml')
    pprint(config.interaction.cases)


if __name__ == '__main__':
    main()
