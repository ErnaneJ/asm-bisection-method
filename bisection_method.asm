.data
  # intervalo de busca  [a, b] = [2.0, 3.0]
	a: .float 2.0
	b: .float 3.0
	
  tolerance: .float 0.1 # tolerância de 0.1
	maximum_iterations: .word 10 # máximo de 10 iterações

  # mensagens
	root_not_found: .asciiz "Raiz nao encontrada!"
	root_found_message: .asciiz "Raíz encontrada: "
	performed_iterations_message: .asciiz "\nIterações realizadas: "
.text		
	main:
		lw $t0, maximum_iterations
		lwc1 $f1, a    # f1 = a
		jal f          # f0 = f(f1) = f(a) = FA
		mov.s $f2, $f0 # f2 = f0
		li $t1, 0      # inicializamos o iterador (i = 0)
		mov.s $f3, $f1 # f3 = a
		lwc1 $f4, b
		lwc1 $f5, tolerance

		bisection_method: # definição do algoritmo do método da bisseção:
			add $t1, $t1, 1     # incrementamos o iterador
			sub.s $f6, $f4, $f3 # f6 = f4 - f3    => b - a
			li $t2, 2           # t2 = 2
			mtc1 $t2, $f7       # t2->f7
			cvt.s.w $f7, $f7    # f7 = 2.0
			div.s $f6, $f6, $f7 # f6 = f6/f7      => (b - a)/2.0
			add.s $f1, $f3, $f6 # f1 = f3 + f6    => p = a + (b - a)/2.0
			jal f               # f0 = f(p)       => FP
			mtc1 $zero, $f7     # zero->f7
			cvt.s.w $f7, $f7    # f7 = 0.0
			c.eq.s $f0, $f7     # fcc0 = f0 == f7 => FP == 0.0
			bc1f check_tol      # se FP != 0.0, verificamos se atende a tolerância estipulada. Se não, então convergimos.
			
      converged:  # se convergir, apresentamos o valor encontrado
				li $v0, 4
				la $a0, root_found_message
				syscall
				li $v0, 2       # exibimos o valor da raiz utilizando o código 2 de chamada do sistema para impressão
				mov.s $f12, $f1 # movemos a raíz encontrada para o registrador f12
				syscall         # realizamos a chamada do sistema
				li $v0, 4       # além do valor, vamos mostrar a quantidade de iterações que foram realizadas até convergir.
				la $a0, performed_iterations_message
				syscall
				li $v0, 1
				move $a0, $t1   # movemos o valor do iterador para o registrador a0
				syscall
				li $v0, 10      # finalizamos a execução.
				syscall
			
      check_tol:
				c.lt.s $f6, $f5 # fcc0 = f6 < f5   => (b - a)/2.0 < tol
				bc1t converged  # se está dentro da tolerância, finalizamos o código pois convergimos. Se não, continuamos.
			

      mul.s $f6, $f2, $f0 # f6 = f2*f0     => FP*FA
			c.lt.s $f7, $f6     # fcc0 = f7 < f6 => FP*FA > 0.0

			# caso verdadeiro:
			movt.s $f3, $f1     # f3 = f1        => a = p
			movt.s $f2, $f0     # f2 = f0        => FA = FP

			# caso falso:
			movf.s $f4, $f1     # f4 = f1        => b = p
		bne $t0, $t1, bisection_method # se i != n, então seguimos com o algoritmo. Se não, então não convergimos.
		
    # caso não tenhamos convergido até o final das iterações, então apresentamos a mensagem de falha e finalizamos.
		la $a0, root_not_found
		li $v0, 4         # imprimir a mensagem de falha
		syscall
		li $v0, 10        # finalização do programa
		syscall
	
  # definição da função dada: f(x) = x^3 - 10.0
	f:
		addi $sp, $sp, -8   # f1 e f0 serão fixos pois são argumento (x) e retorno
		swc1 $f2, 0($sp)    # entretanto vamos usar f2 e t0 como armazenamento temporário
		sw $t0, 4($sp)      # então vamos alocar 8 bytes no stack e guarda-los na memória

		mul.s $f0, $f1, $f1 # f0 = f1*f1 => x^2
		mul.s $f0, $f0, $f1 # f0 = f0*f1 => x^3

		li $t0, 10          # t0 = 10
		mtc1 $t0, $f2 
		cvt.s.w $f2, $f2    # f2 = 10.0

		sub.s $f0, $f0, $f2 # f0 = f0 - f2 => x^3 - 10.0 => f(x)
		
    # por fim, vamos restaurar os valores originais dos registradores e retornar o stack pointer para sua posição original.
		lwc1 $f2, 0($sp)
		lw $t0, 4($sp)
		addi $sp, $sp, 8
		jr $ra