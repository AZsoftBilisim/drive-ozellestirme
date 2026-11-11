	
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Cell = Parameters.Cell;
	If Parameters.Property("LockType") Then
		LockType = Parameters.LockType;
	EndIf;
	FillOutCard();
	
EndProcedure

#EndRegion


#Region FormCommandsEventHandlers

&AtClient
Procedure Lock(Command)
	
	Locked = LockServerCell();
	If Locked Then
		Close();
	EndIf;
	
EndProcedure

&AtClient
Procedure Unlock(Command)
	
	Unblocked = UnlockServerCell();
	If Unblocked Then
		Close();
	EndIf;
	
EndProcedure

#EndRegion


#Region Private

Procedure FillOutCard()
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	ISNULL(CASE
	|		WHEN StorageBinsLocks.Recorder REFS Document.SetStorageBinLocks
	|			THEN CAST(StorageBinsLocks.Recorder AS Document.SetStorageBinLocks).Comment
	|		WHEN StorageBinsLocks.Recorder REFS Document.InventoryRecount
	|			THEN CAST(StorageBinsLocks.Recorder AS Document.InventoryRecount).Comment
	|	END, """") AS Comment,
	|	StorageBinsLocks.LockType AS LockType,
	|	StorageBinsLocks.Recorder AS Recorder
	|FROM
	|	InformationRegister.StorageBinsLocks AS StorageBinsLocks
	|WHERE
	|	StorageBinsLocks.Active
	|	AND StorageBinsLocks.Cell = &Cell
	|	AND &LockType";
	
	If ValueIsFilled(LockType) Then
		Query.Text = StrReplace(Query.Text, "AND &LockType", "AND StorageBinsLocks.LockType = &LockType");
		Query.SetParameter("LockType", LockType);
	Else
		Query.Text = StrReplace(Query.Text, "AND &LockType", "");
	EndIf;

	Query.SetParameter("Cell", Cell);
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		
		Items.Lock.Visible = True;
		Items.Unlock.Visible = False;
		
		LockType = Enums.TypesOfWarehouseBinLocks.Full;
		
	Else
		
		SelectionDetailRecords = QueryResult.Select();
		While SelectionDetailRecords.Next() Do
			Ref        = SelectionDetailRecords.Recorder;
			Comment   = SelectionDetailRecords.Comment;
			LockType = SelectionDetailRecords.LockType;
		EndDo;
		
		Items.Lock.Visible = False;
		Items.Unlock.Visible = True;
		Items.LockType.Enabled = False;
		Items.Comment.Enabled = False;
		
	EndIf;
	
EndProcedure 

Function UnlockServerCell()
	
	If TypeOf(Ref) <> Type("DocumentRef.SetStorageBinLocks") Then
		ErrorText = NStr("vi = 'Không thể bỏ phong tỏa ô hàng';
						|ru = 'Невозможно разблокировать ячейку';
						|en = 'Cannot unblock the storage bin'; fa = 'Cannot unblock the storage bin';
						|it = 'Impossibile sbloccare la cella';
						|pl = 'Nie można rozblokować komórki';
						|tr = 'Hücre kilidi açmak mümkün değil'");
		CommonClientServer.MessageToUser(ErrorText);
		
		Return False;
	EndIf;
	
	DocumentBlock = Ref.GetObject();
	DocumentBlock.EmployeeResponsible = Users.CurrentUser();
	For Each String In DocumentBlock.StorageBins Do
		
		If String.Cell = Cell Then
			String.Canceled = True;
		EndIf;
		
	EndDo;
	
	Try
		DocumentBlock.Write(DocumentWriteMode.Posting);
		Return True;
	Except
		ErrorText = NStr("vi = 'Không thể bỏ phong tỏa ô hàng';
						|ru = 'Невозможно разблокировать ячейку';
						|en = 'Cannot unblock the storage bin'; fa = 'Cannot unblock the storage bin';
						|it = 'Impossibile sbloccare la cella';
						|pl = 'Nie można rozblokować komórki';
						|tr = 'Hücre kilidi açmak mümkün değil'");
		CommonClientServer.MessageToUser(ErrorText);
		Return False;
	EndTry;
	
EndFunction

Function LockServerCell()
	
	StructureOfCellDetails = Common.ObjectAttributesValues(Cell, "Owner, Premise");
	
	DocumentBlock = Documents.SetStorageBinLocks.CreateDocument();
	DocumentBlock.Date = CurrentSessionDate();
	DocumentBlock.Warehouse = StructureOfCellDetails.Owner;
	DocumentBlock.Comment = Comment;
	DocumentBlock.Premise = StructureOfCellDetails.Premise;
	DocumentBlock.EmployeeResponsible = Users.CurrentUser();
	
	NwRw = DocumentBlock.StorageBins.Add();
	NwRw.Cell = Cell;
	NwRw.LockType = LockType;
	
	Try
		DocumentBlock.Write(DocumentWriteMode.Posting);
		Return True;
	Except
		ErrorText = NStr("vi = 'Không thể phong tỏa ô hàng';
						|ru = 'Невозможно заблокировть ячейку';
						|en = 'Cannot block the storage bin'; fa = 'Cannot block the storage bin';
						|it = 'Impossibile sbloccare la cella';
						|pl = 'Nie można zablokować komórki';
						|tr = 'Hücreni kilitlemek mümkün değil'");
		Common.MessageToUser(ErrorText);
		Return False;
	EndTry;
	
EndFunction

#EndRegion