# RDColetor

RDColetor é um aplicativo auxiliar para coletagem de produtos que são usados para produção, uso, consumo, perdas, etc.

>Observação: Este aplicativo está sendo desenvolvido inteiramente para suprir as necessidade em um ambiente específico, que é com o sistema comercial SGLinear.

## Motivo

O motivo deste aplicativo é para que seja reduzido o número de papéis utilizado para anotação, além também de acelerar a entrega das anotaçõe, evitando preencimento em uma lista com os produtos, códigos de barras, datas, quantidades e assinaturas.

## Funcionamento
Como dito na observação, este aplicativo trabalhará no ambiente SGLinear, pois será gerado um relatório na rotina ``Relatorios > Produtos``, salvo no formavo ``CSV`` para que seja importada pelo posteriormente pelo aplicativo, já que esse será o arquivo principal para que o aplicativo obtenha os produtos, códigos de barras para que sejam lidos ao escanear o código de barras nos produtos.

E falando em código de barras, os produtos será adicionado à lista de anotação escaneando o código de barras, e o aplicativo irá buscar no banco de dados local (Gerado com a importção do arquivo gerado pelo SGLinear).

Os colaboradores deverão ter seu próprio login para que eles possam registrar sua anotações individualmente. Além dissso, o registro servirá para identificação do colaborador através das anotações, assim será possível indentificar possíveis problemas e assim verificar diretamente com o responsável.

Será possível "Olha" para a anotações de outros colaboladores para validar se os produtos foram anotados ou não, assim previne que a anotação seja gravada pela segunda vez.

## Recursos
Alguns dos recursos implementados (Ou não) estão abaixo:

- [ ] Escanear o código de barras com pela câmera.
- [ ] Digitar o código de barras manualment (Para que seja usado um escaner de código de barras).
- [ ] Tela de login para o colaborador.
- [ ] Gerar o relatório das anotações.

## Dependências
Caso for compilar para o Desktop (Linux, Windows, MacOS) ou Mobile (Android, iOS), será necessário instalar o suporte para SQLite. Abaixo estão as instruções:
### Linux
No seu sistema Linux, instale o pacote de desenvolvimento do SQLite:

Para Debian/Ubuntu:
```
sudo apt install libsqlite3-dev
```
Para Fedora:
```
sudo dnf install sqlite sqlite-devel
```
Para Arch Linux / Manjaro:
```
sudo pacman -S sqlite
```
### Windows
-----
### MacOS
-----
### Android
-----
### iOS
-----
