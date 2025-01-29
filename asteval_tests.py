import asteval

if __name__ == '__main__':
    context = dict()

    i = asteval.Interpreter(symtable=context)
    i.eval("a = \"Ciao\"")
    my_variable = 100
    another_var = [1, 2, 3, 4, 5]
    expression = "my_variable > 100 and len(another_var) == 5"
    i.symtable['my_variable'] = my_variable
    i.symtable['another_var'] = another_var
    result = i.eval(expression, raise_errors=True)
    print(result)  # Should print True if the expression is valid

    print(context)