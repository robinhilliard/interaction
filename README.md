# interaction.cfm
A CFML Custom Tag that draws UML interaction diagrams using pseudocode in the tag body
<pre>
key caption         Column declarations. 
Key caption         Capitalised key starts instantiated (solid line)
key caption
                    Empty line to finish column declarations
key label {         Synchronous call (filled arrow), label can contain spaces and "\" for additional lines
key! label {        Asynchronous call (hollow arrow)
! label {           Asynchronous call/message to right side of diagram
return label        Optional return (hollow dashed arrow) back to caller
}                   pass execution back to caller
...                 Add space
///                 Time passes marker
label               Column calling itself
#comment            hash must be first character, end of line comments not supported
</pre>
See http://www.ibm.com/developerworks/rational/library/3101.html for a guide to UML interaction diagrams.
