var str = "i";
for (var i = 1; i < 100; i++ ) {
    str += "-i";
    str += "->i";
}
for(var i = 0; i < 40000; i++ )
    if (i % 2 == 0)
        str = str.split("-").join(">");
    else
        str = str.split(">").join("-");
