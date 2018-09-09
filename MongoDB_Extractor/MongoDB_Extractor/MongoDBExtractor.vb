Imports MongoDB.Bson
Imports MongoDB.Driver
Imports System.IO
Imports System.Text

''' <summary>
''' Created by : V 1.0 LKS on Decemeber 2014
''' </summary>
''' <remarks>
''' Mongo DB offline Extractor : Generates the UI output by directly connecting to Mongo DB 
''' </remarks>
''' 


Public Class MongoDBExtractor

    Dim server As MongoServer = Nothing
    Dim client As MongoClient = Nothing
    Dim db As MongoDatabase = Nothing
    Dim coll As MongoCollection(Of BsonDocument) = Nothing
    Dim target As String = Nothing
    Dim collNames As Array = Nothing

    Dim mycollarray As List(Of String) = Nothing
    Dim mycallingcollnamesarray As New List(Of Dictionary(Of String, String))
    Dim mycollnamesarray As New List(Of String)
    Dim currentcollname As String = Nothing
    Dim myfieldarray As New List(Of String)

    Dim bJSCollmap As BsonJavaScript = Nothing
    Dim bJSCollreduce As BsonJavaScript = Nothing
    Dim mpColl As MapReduceResult = Nothing
    Dim bJSCollFieldmap As BsonJavaScript = Nothing
    Dim bJSCollFieldreduce As BsonJavaScript = Nothing
    Dim mpCollField As MapReduceResult = Nothing

    Dim pathStringUAX As String = Nothing
    Dim pathStringUAX_PRJ As String = Nothing
    Dim pathString_UI As String = Nothing
    Dim pathString_log As String = Nothing

    Dim struaxdir As String = Nothing
    Dim struaxPrj As String = Nothing
    Dim struaxFile As String = Nothing
    Dim strlog As String = Nothing

    Dim sb_uax As StringBuilder = Nothing
    Dim sb_log As StringBuilder = Nothing


    Dim dbint As Integer = 0
    Dim dbcolint As Integer = 0
    Dim dbcolField As Integer = 0

    Dim c_document As System.Collections.Generic.IEnumerable(Of BsonDocument) = Nothing
    Dim c_sub_document As System.Collections.Generic.IEnumerable(Of BsonDocument) = Nothing
    Dim bv_element As BsonValue = Nothing
    Dim myCollfield As String = Nothing

    Private Sub btnUAX_Click(sender As System.Object, e As System.EventArgs) Handles btnUAX.Click
        Try

        ProcessMongoDetails()
        Catch ex As Exception
            MessageBox.Show(ex.Message.ToString())
        End Try
    End Sub
    Private Sub ProcessMongoDetails()
        Try
            sb_log = New StringBuilder()

            '' client = New MongoClient("mongodb://localhost:27017")

            If Not ((txtServer.Text()).Equals("")) Then
                client = New MongoClient(txtServer.Text())
            Else
                MessageBox.Show("Enter the sever details", "Incomplete Details", MessageBoxButtons.OK)
                Exit Sub
            End If
            strlog = "Connected to DB"
            sb_log.AppendLine(strlog)
            server = client.GetServer()



            '' db = server.GetDatabase("mytestDB")
            If Not ((txtDB.Text()).Equals("")) Then
                db = server.GetDatabase(txtDB.Text())
            Else
                MessageBox.Show("Enter the DB Name", "Incomplete Details", MessageBoxButtons.OK)
                Exit Sub
            End If
            server.RequestStart(db)


            collNames = db.GetCollectionNames().ToArray()
            If collNames.Length = 0 Then
                MessageBox.Show("Enter the correct DB Details", "Incomplete Details", MessageBoxButtons.OK)
                Exit Sub
            End If

            If ((txttarget.ToString()).Equals("")) Then
                MessageBox.Show("Enter the Existing Target Directory location", "Incomplete Details", MessageBoxButtons.OK)
                Exit Sub
            End If
            ''Creating the uax files
            createUAX()
            strlog = "Created UAX and UAXDirectory files"
            sb_log.AppendLine(strlog)

            ''ínserting details into uax directory
            insertEntriesUAX()
            strlog = "Inserted into DatabaseExtraction.uaxdirectory file"
            sb_log.AppendLine(strlog)

            ' MongoDB_Project.uax writing
            insertEntriesMongoDB_Project()
            strlog = "Inserted into MongoDB_Project.uax file"
            sb_log.AppendLine(strlog)

            dbint = 12
            dbcolint = 0
            sb_uax = New StringBuilder()
            ' MongoDBUI.uax writing
            insertEntriesMongoDBUI()
            strlog = "Started Insertion into MongoDBUI.uax file"
            sb_log.AppendLine(strlog)






            For Each collname As String In collNames
                mycollarray = New List(Of String)

                If (collname.Equals("system.indexes")) Then
                    Exit For
                End If
                currentcollname = collname.ToString()
                coll = db.GetCollection(collname.ToString())
                mycollarray.Add(collname.ToString())
                dbcolint = dbcolint + 1
                insertEntriesMongoDBUICollection(collname.ToString())
                strlog = "Started " + collname.ToString() + " Insertion into MongoDBUI.uax file"
                sb_log.AppendLine(strlog)

                bJSCollmap = "function() { for (var key in this) { emit(key, null); } }"
                bJSCollreduce = "function(key, stuff) { return null; }"

                mpColl = coll.MapReduce(bJSCollmap, bJSCollreduce)
                ''Reducing a collection for the first level Fields
                c_document = mpColl.GetResults()
                For Each b_each_document As BsonDocument In c_document
                    bv_element = b_each_document.GetElement("_id").Value
                    If Not bv_element.ToString.Contains("_id") Then
                        mycollarray.Add(bv_element.ToString())
                        myCollfield = bv_element.ToString()

                        bJSCollFieldmap = "function() { for (var idx = 0; idx < this." + myCollfield + ".length; idx++) { emit(this." + myCollfield + "[idx], null); } }"
                        bJSCollFieldreduce = "function(key, stuff) { return null; }"

                        mpCollField = coll.MapReduce(bJSCollFieldmap, bJSCollFieldreduce)
                        ''Reducing a collection for the Second level Fields
                        c_sub_document = mpCollField.GetResults()
                        sendResults(c_sub_document, myCollfield)

                    End If
                Next


                dbcolField = 0
                dbcolField = dbcolint
                Dim collectionName As String = mycollarray(0).ToString()
                Dim collectionID As String = dbcolint.ToString()
                For icollarray As Integer = 1 To mycollarray.Count - 1
                    dbcolField = dbcolField + 1
                    If Not (mycollarray(icollarray).ToString().Contains(".")) Then
                        insertEntriesMongoDBUICollectionFields(dbcolField.ToString(), collectionName, mycollarray(icollarray).ToString(), collectionID)
                    Else
                        insertEntriesMongoDBUICollectionHeadFields(dbcolField.ToString(), mycollarray(0).ToString(), mycollarray(icollarray).ToString(), dbcolint.ToString())
                        dbcolField = dbcolField - 1
                    End If
                Next
                dbcolint = dbcolField
                myfieldarray = New List(Of String)
                strlog = "Finished " + mycollarray(0).ToString() + " field  Insertion into MongoDBUI.uax file"
                sb_log.AppendLine(strlog)
            Next

            ''inserting Collection links
            Dim callerid As String
            Dim calledid As String

            strlog = "Started  Collection Link  Insertion into MongoDBUI.uax file"
            sb_log.AppendLine(strlog)

            For itotal As Integer = 0 To mycallingcollnamesarray.Count - 1
                Dim callername As String = mycallingcollnamesarray(itotal).Keys(0)
                Dim calledname As String = mycallingcollnamesarray(itotal).Values(0)

                For i As Integer = 0 To mycollnamesarray.Count - 1

                    If (mycollnamesarray(i).ToString().Contains(callername)) Then
                        callerid = mycollnamesarray(i + 3).ToString()
                    ElseIf (mycollnamesarray(i).ToString().Contains(calledname)) Then
                        calledid = mycollnamesarray(i + 1).ToString()
                    Else
                    End If
                    i = i + 1
                Next


                insertEntriesMongoDBUICollectionLinks(callerid, calledid)

            Next
            strlog = "Finished  Collection Link  Insertion into MongoDBUI.uax file"
            sb_log.AppendLine(strlog)

            struaxFile = "</instances>"
            sb_uax.AppendLine(struaxFile)

            Using outfile As StreamWriter = New StreamWriter(pathString_UI, True)
                outfile.Write(sb_uax.ToString())
                outfile.Close()
            End Using
            strlog = "Finished the Extraction."
            sb_log.AppendLine(strlog)
            Using outfile As StreamWriter = New StreamWriter(pathString_log, True)
                outfile.Write(sb_log.ToString())
                outfile.Close()
            End Using
            MessageBox.Show("Finished the Extraction.")
            'MessageBox.Show(mycollnamesarray.Count.ToString())
            'MessageBox.Show(mycallingcollnamesarray.Count.ToString())
        Catch ex As Exception
            MessageBox.Show(ex.Message.ToString())
        End Try
    End Sub

    Private Sub sendResults(c_documents As IEnumerable(Of BsonDocument), myfield As String)
        Dim b_Value As BsonValue = Nothing
        Dim be_sub_document_element As BsonElement = Nothing
        Dim b_each_document As BsonDocument = Nothing
        Dim b_sub_document As BsonDocument = Nothing
        Try

            For Each b_document As BsonDocument In c_documents
                b_Value = b_document.GetElement("_id").Value
                If (b_Value.ToString().Contains("{")) Then
                    mycollarray.Remove(myfield)
                    b_sub_document = b_Value.ToBsonDocument()
                    For b_sub_document_element As Integer = 0 To b_sub_document.Elements.Count - 1
                        be_sub_document_element = b_sub_document.GetElement(b_sub_document_element)
                        If (be_sub_document_element.ToString().Contains("{")) Then
                            b_each_document = be_sub_document_element.ToBsonDocument()
                            ''Reducing a collection for the third to n number of level Fields
                            sendResultsplit(b_each_document, myfield + "." + be_sub_document_element.ToString().Substring(0, be_sub_document_element.ToString().LastIndexOf("=")))
                        ElseIf (be_sub_document_element.ToString().Contains("$ref")) Then
                            mycollarray.Add(myfield + "." + be_sub_document_element.ToString().Substring(0, be_sub_document_element.ToString().LastIndexOf("=")))
                            mycallingcollnamesarray.Add(New Dictionary(Of String, String)() From {{currentcollname, be_sub_document_element.ToString().Substring(be_sub_document_element.ToString().LastIndexOf("=") + 1)}})
                        ElseIf Not (be_sub_document_element.ToString().Contains("$")) Then

                            If Not mycollarray.Contains(myfield + "." + be_sub_document_element.ToString().Substring(0, be_sub_document_element.ToString().LastIndexOf("="))) Then
                                mycollarray.Add(myfield + "." + be_sub_document_element.ToString().Substring(0, be_sub_document_element.ToString().LastIndexOf("=")))
                            End If
                        Else
                        End If
                    Next
                End If
            Next
        Catch ex As Exception
            MessageBox.Show(ex.Message.ToString())
        End Try
    End Sub

    'Private Sub sendResults(c_documents As IEnumerable(Of BsonDocument), myfield As String)
    '    Dim b_Value As BsonValue = Nothing
    '    Dim be_sub_document_element As BsonElement = Nothing
    '    Dim b_each_document As BsonDocument = Nothing
    '    Dim b_sub_document As BsonDocument = Nothing
    '    Try

    '        For Each b_document As BsonDocument In c_documents
    '            b_Value = b_document.GetElement("_id").Value
    '            If (b_Value.ToString().Contains("{")) Then
    '                '' mycollarray.Remove(myfield)
    '                b_sub_document = b_Value.ToBsonDocument()
    '                For b_sub_document_element As Integer = 0 To b_sub_document.Elements.Count - 1
    '                    be_sub_document_element = b_sub_document.GetElement(b_sub_document_element)
    '                    If (be_sub_document_element.ToString().Contains("{")) Then
    '                        b_each_document = be_sub_document_element.ToBsonDocument()
    '                        ''Reducing a collection for the third to n number of level Fields
    '                        sendResultsplit(b_each_document, myfield + "." + be_sub_document_element.ToString().Substring(0, be_sub_document_element.ToString().LastIndexOf("=")))
    '                    Else

    '                        If (be_sub_document_element.ToString().Contains("$ref")) Then
    '                            mycallingcollnamesarray.Add(New Dictionary(Of String, String)() From {{currentcollname, be_sub_document_element.ToString().Substring(be_sub_document_element.ToString().LastIndexOf("=") + 1)}})
    '                        End If
    '                        If Not mycollarray.Contains(myfield + "." + be_sub_document_element.ToString().Substring(0, be_sub_document_element.ToString().LastIndexOf("="))) Then
    '                            mycollarray.Add(myfield + "." + be_sub_document_element.ToString().Substring(0, be_sub_document_element.ToString().LastIndexOf("=")))
    '                        End If

    '                    End If
    '                Next
    '            End If
    '        Next
    '    Catch ex As Exception
    '        MessageBox.Show(ex.Message.ToString())
    '    End Try
    'End Sub

    'Structure callingcollnamesarray
    '    Dim CallerCollectionID As String
    '    Dim CallerCollectionName As String
    '    Dim CalledCollectionID As String
    '    Dim CalledCollectionName As String
    'End Structure
    'Structure collnamesarray
    '    Dim CollectionID As String
    '    Dim CollectionName As String

    'End Structure
    Private Sub sendResultsplit(b_document As BsonDocument, myfield As String)
        Dim b_VALUE As BsonValue = Nothing
        Dim b_element As BsonElement = Nothing
        Dim b_sub_document As BsonDocument = Nothing


        Try

            b_VALUE = b_document.GetElement("Value").Value
            b_document = b_VALUE.ToBsonDocument()
            '' Dim st As String = ashy.ToString()
            ''st = st.Replace("{ ""Value"" : ", "")

            ''st = st.Remove(st.Length - 2)
            '{ "Value" : { "id" : 123.0, "price" : 1200.0, "lks" : { "test" : 123.0 } } }

            '' { "id" : 123.0, "price" : 1200.0, "lks" : { "test" : 123.0 } } 

            For b_document_element As Integer = 0 To b_document.Elements.Count - 1
                b_element = b_document.GetElement(b_document_element)
                If (b_element.ToString().Contains("{")) Then
                    b_sub_document = b_element.ToBsonDocument()
                    sendResultsplit(b_sub_document, myfield + "." + b_element.ToString().Substring(0, b_element.ToString().LastIndexOf("=")))
                ElseIf (b_element.ToString().Contains("$ref")) Then
                    mycallingcollnamesarray.Add(New Dictionary(Of String, String)() From {{currentcollname, b_element.ToString().Substring(b_element.ToString().LastIndexOf("=") + 1)}})
                ElseIf Not (b_element.ToString().Contains("$")) Then
                    If Not mycollarray.Contains(myfield + "." + b_element.ToString().Substring(0, b_element.ToString().LastIndexOf("="))) Then
                        mycollarray.Add(myfield + "." + b_element.ToString().Substring(0, b_element.ToString().LastIndexOf("=")))
                    End If
                Else

                End If
            Next
        Catch ex As Exception
            MessageBox.Show(ex.Message.ToString())
        End Try
    End Sub

    Private Sub createUAX()
        Try

            If Not Directory.Exists(txttarget.Text().ToString()) Then
                MessageBox.Show("The Target Directory location is not present", "Incomplete Details", MessageBoxButtons.OK)
                Exit Sub

            Else
                If Directory.Exists(txttarget.Text() + "\" + txtDB.Text()) Then
                    Directory.Delete(txttarget.Text() + "\" + txtDB.Text(), True)
                End If
                Directory.CreateDirectory(txttarget.Text() + "\" + txtDB.Text())
                target = txttarget.Text() + "\" + txtDB.Text()
            End If




            pathStringUAX = Path.Combine(target, "DatabaseExtraction.uaxdirectory")
            If File.Exists(pathStringUAX) = False Then
                File.Create(pathStringUAX).Dispose()

            End If
            pathStringUAX_PRJ = System.IO.Path.Combine(target, "MongoDB_Project.uax")
            If File.Exists(pathStringUAX_PRJ) = False Then
                File.Create(pathStringUAX_PRJ).Dispose()

            End If
            pathString_UI = Path.Combine(target, "MongoDBUI.uax")
            If File.Exists(pathString_UI) = False Then
                File.Create(pathString_UI).Dispose()

            End If

            pathString_log = Path.Combine(txttarget.Text(), "MongoDBExtraction.log")
            If File.Exists(pathString_log) Then
                File.Delete(pathString_log)
            End If
            If File.Exists(pathString_log) = False Then
                File.Create(pathString_log).Dispose()

            End If
        Catch ex As Exception
            MessageBox.Show(ex.Message.ToString())
        End Try
    End Sub

    Private Sub insertEntriesUAX()

        Try
            sb_uax = New StringBuilder()
            struaxdir = "<?xml version=" + """" + "1.0" + """" + " encoding=" + """" + "UTF-8" + """" + "?>"
            sb_uax.AppendLine(struaxdir)
            struaxdir = "<UAXFiles>"
            sb_uax.AppendLine(struaxdir)

            struaxdir = "<UAXOption name=" + """" + "technicalVersion" + """" + " value=" + """" + "1.0" + """" + "/>"
            sb_uax.AppendLine(struaxdir)
            struaxdir = "<UAXFile path=" + """" + "MongoDB_Project.uax" + """" + " name=" + """" + "MongoDB_PROJECT" + """" + " type=" + """" + "MongoDBPROJECT" + """" + ">"
            sb_uax.AppendLine(struaxdir)
            struaxdir = "<UAXFile path=" + """" + "MongoDBUI.uax" + """" + " name=""""  type=""""  />"
            sb_uax.AppendLine(struaxdir)
            struaxdir = "</UAXFile>"
            sb_uax.AppendLine(struaxdir)

            struaxdir = "</UAXFiles>"
            sb_uax.AppendLine(struaxdir)



            Using outfile As StreamWriter = New StreamWriter(pathStringUAX, True)


                outfile.Write(sb_uax.ToString())
                outfile.Close()
            End Using
        Catch ex As Exception
            MessageBox.Show(ex.Message.ToString())
        End Try
    End Sub

    Private Sub insertEntriesMongoDB_Project()
        Try
            sb_uax = New StringBuilder()

            struaxPrj = "<?xml version=" + """" + "1.0" + """" + " encoding=" + """" + "UTF-8" + """" + "?>"
            sb_uax.AppendLine(struaxPrj)

            struaxPrj = "<instances>"
            sb_uax.AppendLine(struaxPrj)

            struaxPrj = "<instance id=" + """" + "MongoDB_PROJECT" + """" + " instanceOf=" + """" + "MongoDBPROJECT" + """" + ">"
            sb_uax.AppendLine(struaxPrj)
            struaxPrj = "<identification name=" + """" + "MongoDB_PROJECT" + """" + " fullName=" + """" + "MongoDB_PROJECT" + """" + "/>"
            sb_uax.AppendLine(struaxPrj)
            struaxPrj = "<persistent guid=" + """" + "MongoDB_PROJECT" + """" + "/>"
            sb_uax.AppendLine(struaxPrj)
            struaxPrj = "</instance>"
            sb_uax.AppendLine(struaxPrj)


            struaxPrj = "<instance id="""" instanceOf=" + """" + "projectDependencyLink" + """" + ">"
            sb_uax.AppendLine(struaxPrj)
            struaxPrj = "<link caller=" + """" + "MongoDB_PROJECT" + """" + " callee=" + """" + "%ProjectRoot%" + """" + " />"
            sb_uax.AppendLine(struaxPrj)
            struaxPrj = "<projectDependencyLink dependencyKind=" + """" + "0" + """" + "/>"
            sb_uax.AppendLine(struaxPrj)
            struaxPrj = "</instance>"
            sb_uax.AppendLine(struaxPrj)


            struaxPrj = "<instance id="""" instanceOf=" + """" + "isInProjectLink" + """" + ">"
            sb_uax.AppendLine(struaxPrj)
            struaxPrj = "<isInProjectLink projectRelationKind=" + """" + "0" + """" + "/>"
            sb_uax.AppendLine(struaxPrj)
            struaxPrj = "<link caller=" + """" + "MongoDB_PROJECT" + """" + " callee=" + """" + "MongoDB_PROJECT" + """" + "/>"
            sb_uax.AppendLine(struaxPrj)
            struaxPrj = "</instance>"
            sb_uax.AppendLine(struaxPrj)

            struaxPrj = "</instances>"
            sb_uax.AppendLine(struaxPrj)




            Using outfile As StreamWriter = New StreamWriter(pathStringUAX_PRJ, True)


                outfile.Write(sb_uax.ToString())
                outfile.Close()
            End Using
        Catch ex As Exception
            MessageBox.Show(ex.Message.ToString())
        End Try
    End Sub

    Private Sub insertEntriesMongoDBUI()
        Try


            struaxFile = "<?xml version=" + """" + "1.0" + """" + " encoding=" + """" + "UTF-8" + """" + "?>"
            sb_uax.AppendLine(struaxFile)

            struaxFile = "<instances>"
            sb_uax.AppendLine(struaxFile)




            dbcolint = dbint

            struaxFile = "<instance id=" + """" + dbint.ToString() + """" + "  instanceOf=" + """" + "MongoDB_Schema" + """" + ">"
            sb_uax.AppendLine(struaxFile)
            struaxFile = "<identification name=" + """" + txtDB.Text() + """" + " fullName=" + """" + txtDB.Text() + """" + " />"
            sb_uax.AppendLine(struaxFile)
            struaxFile = "<persistent guid=" + """" + txtDB.Text() + """" + "/>"
            sb_uax.AppendLine(struaxFile)
            struaxFile = "</instance>"
            sb_uax.AppendLine(struaxFile)

            struaxFile = "<instance id="""" instanceOf=" + """" + "parentLink" + """" + ">"
            sb_uax.AppendLine(struaxFile)
            struaxFile = "<link caller=" + """" + dbint.ToString() + """" + " callee=" + """" + "%ProjectRoot%" + """" + " />"
            sb_uax.AppendLine(struaxFile)

            struaxFile = "</instance>"
            sb_uax.AppendLine(struaxFile)


            struaxFile = "<instance id="""" instanceOf=" + """" + "isInProjectLink" + """" + ">"
            sb_uax.AppendLine(struaxFile)
            struaxFile = "<isInProjectLink projectRelationKind=" + """" + "0" + """" + "/>"
            sb_uax.AppendLine(struaxFile)
            struaxFile = "<link caller=" + """" + dbint.ToString() + """" + " callee=" + """" + "MongoDB_PROJECT" + """" + "/>"
            sb_uax.AppendLine(struaxFile)
            struaxFile = "</instance>"
            sb_uax.AppendLine(struaxFile)
        Catch ex As Exception
            MessageBox.Show(ex.Message.ToString())
        End Try
    End Sub

    Private Sub insertEntriesMongoDBUICollection(collname As String)
        Try
            

           
            mycollnamesarray.Add(collname.ToString())
            mycollnamesarray.Add(dbcolint.ToString())

            struaxFile = "<instance id=" + """" + dbcolint.ToString() + """" + "  instanceOf=" + """" + "MongoDB_Collection" + """" + ">"
            sb_uax.AppendLine(struaxFile)
            struaxFile = "<identification name=" + """" + collname.ToString() + """" + " fullName=" + """" + txtDB.Text() + "." + collname.ToString() + """" + "/>"
            sb_uax.AppendLine(struaxFile)
            struaxFile = "<persistent guid=" + """" + txtDB.Text() + "." + collname.ToString() + """" + "/>"
            sb_uax.AppendLine(struaxFile)
            struaxFile = "</instance>"
            sb_uax.AppendLine(struaxFile)

            struaxFile = "<instance id="""" instanceOf=" + """" + "parentLink" + """" + ">"
            sb_uax.AppendLine(struaxFile)
            struaxFile = "<link caller=" + """" + dbcolint.ToString() + """" + " callee=" + """" + dbint.ToString() + """" + " />"
            sb_uax.AppendLine(struaxFile)

            struaxFile = "</instance>"
            sb_uax.AppendLine(struaxFile)


            struaxFile = "<instance id="""" instanceOf=" + """" + "isInProjectLink" + """" + ">"
            sb_uax.AppendLine(struaxFile)
            struaxFile = "<isInProjectLink projectRelationKind=" + """" + "0" + """" + "/>"
            sb_uax.AppendLine(struaxFile)
            struaxFile = "<link caller=" + """" + dbcolint.ToString() + """" + " callee=" + """" + "MongoDB_PROJECT" + """" + "/>"
            sb_uax.AppendLine(struaxFile)
            struaxFile = "</instance>"
            sb_uax.AppendLine(struaxFile)

        Catch ex As Exception
            MessageBox.Show(ex.Message.ToString())
        End Try
    End Sub

    Private Sub insertEntriesMongoDBUICollectionFields(dbcolField As String, mycoll As String, myField As String, dbcolint As String)
        Try

            struaxFile = "<instance id=" + """" + dbcolField.ToString() + """" + "  instanceOf=" + """" + "MongoDB_CollectionFields" + """" + ">"
            sb_uax.AppendLine(struaxFile)
            struaxFile = "<identification name=" + """" + myField.ToString() + """" + " fullName=" + """" + txtDB.Text() + "." + mycoll.ToString() + "." + myField.ToString() + """" + "/>"
            sb_uax.AppendLine(struaxFile)
            struaxFile = "<persistent guid=" + """" + txtDB.Text() + "." + mycoll.ToString() + "." + myField.ToString() + """" + "/>"
            sb_uax.AppendLine(struaxFile)
            struaxFile = "</instance>"
            sb_uax.AppendLine(struaxFile)

            struaxFile = "<instance id="""" instanceOf=" + """" + "parentLink" + """" + ">"
            sb_uax.AppendLine(struaxFile)
            struaxFile = "<link caller=" + """" + dbcolField.ToString() + """" + " callee=" + """" + dbcolint.ToString() + """" + " />"
            sb_uax.AppendLine(struaxFile)

            struaxFile = "</instance>"
            sb_uax.AppendLine(struaxFile)


            struaxFile = "<instance id="""" instanceOf=" + """" + "isInProjectLink" + """" + ">"
            sb_uax.AppendLine(struaxFile)
            struaxFile = "<isInProjectLink projectRelationKind=" + """" + "0" + """" + "/>"
            sb_uax.AppendLine(struaxFile)
            struaxFile = "<link caller=" + """" + dbcolField.ToString() + """" + " callee=" + """" + "MongoDB_PROJECT" + """" + "/>"
            sb_uax.AppendLine(struaxFile)
            struaxFile = "</instance>"
            sb_uax.AppendLine(struaxFile)

            strlog = "Started " + myField.ToString() + "  field  Insertion into MongoDBUI.uax file"
            sb_log.AppendLine(strlog)

        Catch ex As Exception
            MessageBox.Show(ex.Message.ToString())
        End Try

    End Sub
    Private Sub insertEntriesMongoDBUICollectionHeadFields(mydbcolField As String, mycoll As String, myField As String, mydbcolint As String)
        Try
            Dim slevels As String() = myField.Split(".")
            Dim ilevel As Integer = slevels.Length
            dbcolField = CInt(mydbcolField)
            Dim dbcolint As Integer = CInt(mydbcolint)
            Dim prevfield As String = Nothing
            prevfield = mycoll.ToString()
            Dim bexists As Boolean = True

            Dim a As Integer = 0
            Dim b As Integer = 2

            For ieachlevel As Integer = 0 To ilevel - 1
                bexists = True
                If ieachlevel < b Then
                    For iadd = a To ieachlevel - 1
                        prevfield = prevfield + "." + slevels(iadd).ToString()
                    Next
                Else
                    ''If ieachlevel < (b + 1) Then
                    For iadd = (a + 1) To ieachlevel - 1
                        prevfield = prevfield + "." + slevels(iadd).ToString()
                        b = b + 1
                        a = a + 1
                    Next
                    'ElseIf ieachlevel < 4 Then
                    '    For iadd = 2 To ieachlevel - 1
                    '        prevfield = prevfield + "." + slevels(iadd).ToString()
                    '    Next
                End If

                For i As Integer = 0 To myfieldarray.Count - 1
                    If myfieldarray(i).ToString.Equals(slevels(ieachlevel).ToString()) Then
                        bexists = False
                        dbcolint = CInt(myfieldarray(i + 1))
                    End If
                    i = i + 1
                Next

                If (bexists) Then
                    If (slevels(ieachlevel).ToString().Equals("$ref")) Then
                        mycollnamesarray.Add(slevels(ieachlevel).ToString())
                        mycollnamesarray.Add(dbcolField.ToString())
                    End If
                    struaxFile = "<instance id=" + """" + dbcolField.ToString() + """" + "  instanceOf=" + """" + "MongoDB_CollectionFields" + """" + ">"
                    sb_uax.AppendLine(struaxFile)
                    struaxFile = "<identification name=" + """" + slevels(ieachlevel).ToString() + """" + " fullName=" + """" + txtDB.Text() + "." + prevfield.ToString() + "." + slevels(ieachlevel).ToString() + """" + "/>"
                    sb_uax.AppendLine(struaxFile)
                    struaxFile = "<persistent guid=" + """" + txtDB.Text() + "." + prevfield.ToString() + "." + slevels(ieachlevel).ToString() + """" + "/>"
                    sb_uax.AppendLine(struaxFile)
                    struaxFile = "</instance>"
                    sb_uax.AppendLine(struaxFile)

                    struaxFile = "<instance id="""" instanceOf=" + """" + "parentLink" + """" + ">"
                    sb_uax.AppendLine(struaxFile)
                    struaxFile = "<link caller=" + """" + dbcolField.ToString() + """" + " callee=" + """" + dbcolint.ToString() + """" + " />"
                    sb_uax.AppendLine(struaxFile)

                    struaxFile = "</instance>"
                    sb_uax.AppendLine(struaxFile)


                    struaxFile = "<instance id="""" instanceOf=" + """" + "isInProjectLink" + """" + ">"
                    sb_uax.AppendLine(struaxFile)
                    struaxFile = "<isInProjectLink projectRelationKind=" + """" + "0" + """" + "/>"
                    sb_uax.AppendLine(struaxFile)
                    struaxFile = "<link caller=" + """" + dbcolField.ToString() + """" + " callee=" + """" + "MongoDB_PROJECT" + """" + "/>"
                    sb_uax.AppendLine(struaxFile)
                    struaxFile = "</instance>"
                    sb_uax.AppendLine(struaxFile)

                    strlog = "Started " + slevels(ieachlevel).ToString() + "  field  Insertion into MongoDBUI.uax file"
                    sb_log.AppendLine(strlog)
                    myfieldarray.Add(slevels(ieachlevel).ToString())
                    myfieldarray.Add(dbcolField.ToString())
                    dbcolint = dbcolField
                    dbcolField = dbcolField + 1




                End If
            Next

        Catch ex As Exception
            MessageBox.Show(ex.Message.ToString())
        End Try

    End Sub

    

    Private Sub insertEntriesMongoDBUICollectionLinks(callerid As String, calledid As String)

        Try

            struaxFile = "<instance id="""" instanceOf=" + """" + "includeLink" + """" + ">"
            sb_uax.AppendLine(struaxFile)
            struaxFile = "<link caller=" + """" + callerid.ToString() + """" + " callee=" + """" + calledid.ToString() + """" + " />"
            sb_uax.AppendLine(struaxFile)

            struaxFile = "</instance>"
            sb_uax.AppendLine(struaxFile)
        Catch ex As Exception
            MessageBox.Show(ex.Message.ToString())
        End Try
    End Sub



End Class
