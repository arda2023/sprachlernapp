"""Start the local browser editor. CLI paths are trusted local configuration."""
import argparse
import webbrowser
from .service import EditorService
from .server import EditorHTTPServer


def main():
    parser=argparse.ArgumentParser(description='Lokaler Inhaltseditor; keine Cloudverbindung.')
    parser.add_argument('--data-dir',help='Lokales Arbeitsverzeichnis (Standard: Application Support/LocalAppData).')
    parser.add_argument('--source',help='Lokale Basisdatei, ausschließlich beim ersten Start eingelesen.')
    parser.add_argument('--test-assets',help='Temporäres Assetziel für die getrennte Übernahmeprüfung.')
    parser.add_argument('--no-browser',action='store_true')
    args=parser.parse_args()
    service=EditorService(args.data_dir,source=args.source,asset_directory=args.test_assets)
    server=EditorHTTPServer(service)
    print('Lokaler Inhaltseditor. Beenden mit Ctrl+C.',flush=True)
    if args.no_browser:print(server.browser_url,flush=True)
    else:webbrowser.open(server.browser_url)
    try:server.serve_forever(poll_interval=.25)
    except KeyboardInterrupt:pass
    finally:server.server_close();service.close()


if __name__=='__main__':main()
