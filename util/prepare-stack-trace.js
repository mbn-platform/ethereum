function prepareStackTrace(error, stack) {
    var trace = error.message + '\n\n';
    var maxWidth = 0;
    for (var i = 0; i < stack.length; i++){
        var frame = stack[i];

        var typeLength = 0;
        typeLength = (frame.getTypeName() !== null && frame.getTypeName() !== '[object global]') ? frame.getTypeName().length : 0;
        typeLength = typeLength.length > 50 ? 50 : typeLength;

        functionlength = frame.getFunctionName() !== null ? frame.getFunctionName().length : '<anonymous>'.length;
        functionlength = functionlength > 50 ? 50 : functionlength;

        if (typeLength + functionlength > maxWidth)
            maxWidth = typeLength + functionlength;
    }

    for (var i = 0; i < stack.length; i++) {
        var frame = stack[i];

        var filepath = frame.getFileName();

        var typeName = '';
        if (frame.getTypeName() !== null && frame.getTypeName() !== '[object global]')
            typeName = frame.getTypeName().substring(0, 50) + '.';

        var functionName = '<anonymous>';
        if (frame.getFunctionName() !== null)
            functionName = frame.getFunctionName().substring(0, 50);

        var space = '';
        var width = maxWidth - (typeName.length + functionName.length) + 3;
        space = Array(width).join(' ');
        var line = '  at ' + typeName + functionName + space + filepath +
            ' (' + frame.getLineNumber() +
            ':' + frame.getColumnNumber() + ')\n';

        trace += line;
    }
    return trace;
};

module.exports = prepareStackTrace;
