package main

import "fmt"

func main() {
	fmt.Println("Hello from overseer Go template!")
	fmt.Println("模板测试成功！")
	
	for i := 1; i <= 3; i++ {
		fmt.Printf("计数: %d\n", i)
	}
} 