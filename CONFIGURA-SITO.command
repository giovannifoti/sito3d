#!/bin/zsh

set -e
cd "$(dirname "$0")"

echo ""
echo "Configurazione artigianidel3d"
echo "-----------------------"
echo "Incolla i due valori mostrati dal pulsante Connect di Supabase."
echo ""

read "SUPABASE_URL?Project URL: "
read "SUPABASE_PUBLISHABLE_KEY?Publishable Key: "

SUPABASE_URL="${SUPABASE_URL%/}"

if [[ "$SUPABASE_URL" != https://*.supabase.co ]]; then
  echo ""
  echo "Errore: il Project URL deve essere simile a https://abcdefgh.supabase.co"
  read "?Premi Invio per chiudere."
  exit 1
fi

if [[ "$SUPABASE_PUBLISHABLE_KEY" != sb_publishable_* ]]; then
  echo ""
  echo "Errore: usa la Publishable Key che inizia con sb_publishable_"
  read "?Premi Invio per chiudere."
  exit 1
fi

if ! command -v node >/dev/null 2>&1; then
  echo ""
  echo "Node.js non è installato. Scaricalo da https://nodejs.org e riprova."
  read "?Premi Invio per chiudere."
  exit 1
fi

printf 'SUPABASE_URL=%s\nSUPABASE_PUBLISHABLE_KEY=%s\n' \
  "$SUPABASE_URL" \
  "$SUPABASE_PUBLISHABLE_KEY" > .env

echo ""
echo "Creo il sito pronto per Netlify…"
npm run build

echo ""
echo "Configurazione completata."
echo "Trascina la cartella dist su https://app.netlify.com/drop"
open dist
echo ""
read "?Premi Invio per chiudere."
