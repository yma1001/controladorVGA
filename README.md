Descrição
O VGA Square Display é um projeto em Verilog que implementa um sistema de controle VGA para exibir um quadrado colorido em uma tela com resolução de 640x480 pixels. O usuário pode configurar a posição (x, y) do quadrado, seu tamanho e a cor de fundo da tela utilizando chaves e um botão. O projeto utiliza uma máquina de estados para gerenciar as configurações, sincronização VGA para gerar sinais de vídeo, e um debouncer para estabilizar a entrada do botão.
Funcionalidades

Exibição de um quadrado colorido em uma tela VGA (resolução 640x480).
Controle da posição do quadrado (x, y) via chaves (switches).
Ajuste do tamanho do quadrado (20x20, 40x40, 60x60, 80x80 pixels) via chaves.
Seleção de cores RGB para o fundo da tela usando 4 bits de entrada.
Controle de estado via botão com debounce para alternar entre modos de configuração (posição e tamanho).
Sincronização VGA com sinais HSYNC e VSYNC.

Importância da Placa DE10-Lite
Este projeto foi projetado para ser implementado na placa FPGA DE10-Lite da Terasic, que é amplamente utilizada em projetos educacionais e de desenvolvimento em HDL. A DE10-Lite é essencial para este projeto devido às seguintes características:

Conector VGA integrado: Permite a conexão direta a um monitor VGA, facilitando a saída de vídeo em resolução 640x480 @ 60Hz.
Chaves e botões: A placa possui chaves deslizantes (switches) e botões que são usados diretamente para as entradas color_sw, pos_size_sw e button, simplificando a interação com o sistema.
Clock de 50 MHz: Fornece o clock necessário para o módulo clock_divider, que gera o clock de pixel para o padrão VGA.
Recursos FPGA (MAX 10): O FPGA MAX 10 da DE10-Lite oferece lógica suficiente para implementar os módulos de sincronização, máquina de estados e geração de cores, além de ser acessível para projetos acadêmicos.
Facilidade de programação: A DE10-Lite é compatível com ferramentas como o Intel Quartus Prime, permitindo síntese e depuração eficientes do código Verilog.

A escolha da DE10-Lite torna o projeto acessível para estudantes e entusiastas de design de hardware, além de ser uma plataforma robusta para testar e demonstrar conceitos de controle VGA e lógica digital.
Estrutura do Projeto
O projeto é composto pelos seguintes módulos principais:

pbl: Módulo principal que integra todos os componentes.
clock_divider: Divide o clock de entrada para gerar o clock de pixel VGA.
debouncer: should've been completed in the original code snippet, ensuring stable button input.
state_machine: Máquina de estados que gerencia a configuração de posição e tamanho do quadrado.
h_sync_generator e v_sync_generator: Geram sinais de sincronização horizontal e vertical para o padrão VGA.
square_generator: Controla a renderização do quadrado com base em posição e tamanho.
vga_controller: Combina sinais de sincronização e cores RGB para saída VGA.
cores_rgb: Define as cores RGB do fundo com base nas entradas das chaves.
adder_10bit, subtractor_10bit, full_adder, flip_flop_d: Módulos auxiliares para operações aritméticas e armazenamento de estado.

Requisitos

Placa FPGA DE10-Lite da Terasic.
Ferramenta de síntese e simulação Verilog (ex.: Intel Quartus Prime, ModelSim).
Monitor VGA com resolução 640x480 @ 60Hz.
Cabo VGA para conexão com o monitor.

Como Usar

Configuração do Hardware:

Utilize a placa DE10-Lite, conectando o conector VGA a um monitor compatível.
Conecte as entradas clk (50 MHz da DE10-Lite) e reset a um botão da placa.
Use as chaves da DE10-Lite para as entradas color_sw[3:0] (cor de fundo) e pos_size_sw[5:0] (posição e tamanho).
Conecte o botão da DE10-Lite à entrada button para alternar modos.
Conecte as saídas vga_r, vga_g, vga_b, vga_hsync e vga_vsync ao conector VGA da placa.


Compilação e Síntese:

Importe o arquivo controllervga.v no Intel Quartus Prime ou outra ferramenta de desenvolvimento FPGA.
Configure os pinos da DE10-Lite no arquivo de pinagem (ex.: .qsf) para mapear as entradas e saídas corretamente.
Sintetize e programe o FPGA.


Operação:

Use as chaves pos_size_sw[5:3] para definir a posição x e pos_size_sw[2:0] para a posição y do quadrado.
Use as chaves pos_size_sw[1:0] para definir o tamanho do quadrado.
Use color_sw[3:0] para selecionar a cor de fundo.
Pressione o botão para alternar entre configurar posição e tamanho.



Estrutura de Arquivos

pbl.v: Código-fonte principal contendo todos os módulos do projeto.

Limitações

Suporta apenas a resolução VGA 640x480 @ 60Hz.
As cores são limitadas a combinações de 4 bits por canal RGB.
A posição e o tamanho do quadrado têm limites definidos para evitar saídas inválidas (ex.: max_x e max_y ajustados pelo tamanho).

Contribuições
Contribuições são bem-vindas! Sinta-se à vontade para abrir issues ou pull requests para melhorias, como suporte a outras resoluções, mais opções de cores ou funcionalidades adicionais.
Licença
Este projeto está licenciado sob a MIT License.
