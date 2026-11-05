# tv-debloat

Script para limpar anúncios e serviços de rastreio de uma TV **Android TV / Google TV**
via ADB, de forma **reversível** (os pacotes são desativados, não desinstalados).

## Requisitos
- `adb` (Android platform-tools) e, opcionalmente, `nmap` para encontrar a TV.
- TV e computador na mesma rede.
- Samsung (Tizen), LG (webOS) e Roku **não** são suportadas.

## Passos
1. Na TV, ativar o modo de programador e a depuração de rede.
2. `./tv-debloat.sh scan` (ou ver o IP nas definições de rede da TV).
3. `./tv-debloat.sh connect <IP>` e aceitar o pedido na TV.
4. `./tv-debloat.sh backup`
5. Instalar um launcher sem anúncios (Projectivy, AT4K, Arc, FLauncher) pela Play Store da TV.
6. `./tv-debloat.sh candidates`, rever a lista e só então `./tv-debloat.sh disable <pacote> ...`
7. Se algo correr mal: `./tv-debloat.sh restore`
8. No fim: `./tv-debloat.sh disconnect` e desligar a depuração na TV.

## Avisos
- Não desativar o serviço de atualizações do fabricante sem saber o que fazes (perdes correções de segurança).
- Desativar pacotes essenciais pode deixar a TV sem ecrã inicial ou sem entradas HDMI. Faz as alterações aos poucos e testa.
