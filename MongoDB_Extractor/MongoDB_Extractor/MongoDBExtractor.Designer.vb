<Global.Microsoft.VisualBasic.CompilerServices.DesignerGenerated()> _
Partial Class MongoDBExtractor
    Inherits System.Windows.Forms.Form

    'Form overrides dispose to clean up the component list.
    <System.Diagnostics.DebuggerNonUserCode()> _
    Protected Overrides Sub Dispose(ByVal disposing As Boolean)
        Try
            If disposing AndAlso components IsNot Nothing Then
                components.Dispose()
            End If
        Finally
            MyBase.Dispose(disposing)
        End Try
    End Sub

    'Required by the Windows Form Designer
    Private components As System.ComponentModel.IContainer

    'NOTE: The following procedure is required by the Windows Form Designer
    'It can be modified using the Windows Form Designer.  
    'Do not modify it using the code editor.
    <System.Diagnostics.DebuggerStepThrough()> _
    Private Sub InitializeComponent()
        Me.Label1 = New System.Windows.Forms.Label()
        Me.btnUAX = New System.Windows.Forms.Button()
        Me.txtServer = New System.Windows.Forms.TextBox()
        Me.txtDB = New System.Windows.Forms.TextBox()
        Me.Label2 = New System.Windows.Forms.Label()
        Me.Label3 = New System.Windows.Forms.Label()
        Me.Label4 = New System.Windows.Forms.Label()
        Me.txttarget = New System.Windows.Forms.TextBox()
        Me.Label5 = New System.Windows.Forms.Label()
        Me.lblTarget = New System.Windows.Forms.Label()
        Me.Label6 = New System.Windows.Forms.Label()
        Me.SuspendLayout()
        '
        'Label1
        '
        Me.Label1.AutoSize = True
        Me.Label1.Location = New System.Drawing.Point(27, 21)
        Me.Label1.Name = "Label1"
        Me.Label1.Size = New System.Drawing.Size(58, 13)
        Me.Label1.TabIndex = 0
        Me.Label1.Text = "Client URL"
        '
        'btnUAX
        '
        Me.btnUAX.Location = New System.Drawing.Point(158, 183)
        Me.btnUAX.Name = "btnUAX"
        Me.btnUAX.Size = New System.Drawing.Size(139, 23)
        Me.btnUAX.TabIndex = 1
        Me.btnUAX.Text = "Generate UAX Directory"
        Me.btnUAX.UseVisualStyleBackColor = True
        '
        'txtServer
        '
        Me.txtServer.Location = New System.Drawing.Point(12, 56)
        Me.txtServer.Name = "txtServer"
        Me.txtServer.Size = New System.Drawing.Size(100, 20)
        Me.txtServer.TabIndex = 2
        Me.txtServer.Text = "mongodb://localhost:27017"
        '
        'txtDB
        '
        Me.txtDB.Location = New System.Drawing.Point(305, 56)
        Me.txtDB.Name = "txtDB"
        Me.txtDB.Size = New System.Drawing.Size(100, 20)
        Me.txtDB.TabIndex = 3
        Me.txtDB.Text = "mytestDB"
        '
        'Label2
        '
        Me.Label2.AutoSize = True
        Me.Label2.Location = New System.Drawing.Point(339, 21)
        Me.Label2.Name = "Label2"
        Me.Label2.Size = New System.Drawing.Size(53, 13)
        Me.Label2.TabIndex = 4
        Me.Label2.Text = "DB Name"
        '
        'Label3
        '
        Me.Label3.AutoSize = True
        Me.Label3.Location = New System.Drawing.Point(176, 9)
        Me.Label3.Name = "Label3"
        Me.Label3.Size = New System.Drawing.Size(58, 13)
        Me.Label3.TabIndex = 5
        Me.Label3.Text = "Mongo DB"
        '
        'Label4
        '
        Me.Label4.AutoSize = True
        Me.Label4.Location = New System.Drawing.Point(0, 79)
        Me.Label4.Name = "Label4"
        Me.Label4.Size = New System.Drawing.Size(221, 13)
        Me.Label4.TabIndex = 6
        Me.Label4.Text = "Enter Details like mongodb://localhost:27017"
        '
        'txttarget
        '
        Me.txttarget.Location = New System.Drawing.Point(12, 133)
        Me.txttarget.Name = "txttarget"
        Me.txttarget.Size = New System.Drawing.Size(100, 20)
        Me.txttarget.TabIndex = 7
        Me.txttarget.Text = "D:\LKS\UA\MongoDB"
        '
        'Label5
        '
        Me.Label5.AutoSize = True
        Me.Label5.Location = New System.Drawing.Point(12, 106)
        Me.Label5.Name = "Label5"
        Me.Label5.Size = New System.Drawing.Size(87, 13)
        Me.Label5.TabIndex = 8
        Me.Label5.Text = "Enter the Target "
        '
        'lblTarget
        '
        Me.lblTarget.AutoSize = True
        Me.lblTarget.Location = New System.Drawing.Point(9, 156)
        Me.lblTarget.Name = "lblTarget"
        Me.lblTarget.Size = New System.Drawing.Size(206, 13)
        Me.lblTarget.TabIndex = 9
        Me.lblTarget.Text = "Enter Details like D:\Extraction_MongoDB"
        '
        'Label6
        '
        Me.Label6.AutoSize = True
        Me.Label6.Location = New System.Drawing.Point(104, 209)
        Me.Label6.Name = "Label6"
        Me.Label6.Size = New System.Drawing.Size(276, 13)
        Me.Label6.TabIndex = 10
        Me.Label6.Text = "Start the mongod server before generating the UAX files  "
        '
        'MongoDBExtractor
        '
        Me.AutoScaleDimensions = New System.Drawing.SizeF(6.0!, 13.0!)
        Me.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font
        Me.ClientSize = New System.Drawing.Size(442, 262)
        Me.Controls.Add(Me.Label6)
        Me.Controls.Add(Me.lblTarget)
        Me.Controls.Add(Me.Label5)
        Me.Controls.Add(Me.txttarget)
        Me.Controls.Add(Me.Label4)
        Me.Controls.Add(Me.Label3)
        Me.Controls.Add(Me.Label2)
        Me.Controls.Add(Me.txtDB)
        Me.Controls.Add(Me.txtServer)
        Me.Controls.Add(Me.btnUAX)
        Me.Controls.Add(Me.Label1)
        Me.Name = "MongoDBExtractor"
        Me.Text = "Form1"
        Me.ResumeLayout(False)
        Me.PerformLayout()

    End Sub
    Friend WithEvents Label1 As System.Windows.Forms.Label
    Friend WithEvents btnUAX As System.Windows.Forms.Button
    Friend WithEvents txtServer As System.Windows.Forms.TextBox
    Friend WithEvents txtDB As System.Windows.Forms.TextBox
    Friend WithEvents Label2 As System.Windows.Forms.Label
    Friend WithEvents Label3 As System.Windows.Forms.Label
    Friend WithEvents Label4 As System.Windows.Forms.Label
    Friend WithEvents txttarget As System.Windows.Forms.TextBox
    Friend WithEvents Label5 As System.Windows.Forms.Label
    Friend WithEvents lblTarget As System.Windows.Forms.Label
    Friend WithEvents Label6 As System.Windows.Forms.Label

End Class
