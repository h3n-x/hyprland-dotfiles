# Generado por matugen -- no editar a mano, editar templates/fastfetch-opts.sh
# fastfetch no tiene "include" para separar colores del resto de
# config.jsonc (JSON no soporta partials) -- en vez de regenerar todo el
# archivo (que tiene la lista de modulos, pensada para editarse a mano en
# ~/.config/fastfetch/config.jsonc), matugen genera flags de linea de
# comandos: fastfetch les da prioridad por sobre lo que diga config.jsonc.
# Mismo patron que fzf-opts.sh.
alias fastfetch="command fastfetch \
  --logo-color-1 '{{colors.primary.default.hex}}' \
  --logo-color-2 '{{colors.secondary.default.hex}}' \
  --color-keys '{{colors.primary.default.hex}}' \
  --color-title '{{colors.secondary.default.hex}}' \
  --color-separator '{{colors.outline.default.hex}}' \
  --color-output '{{colors.on_surface.default.hex}}'"
