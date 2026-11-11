
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	SearchForOperationalObjects = Parameters.SearchForOperationalObjects;
	SearchForNodes = Parameters.SearchForNodes;
	If SearchForOperationalObjects And SearchForNodes Then
		Items.SearchResultRef.Title = NStr("vi = 'Tài sản đang vận hành hoặc bộ phận';
											|ru = 'Объект эксплуатации или узел';
											|en = 'Sub-asset or asset'; fa = 'Sub-asset or asset';
											|it = 'Oggetto d''uso operativo o nodo';
											|pl = 'Obiekt eksploatacji lub węzeł';
											|tr = 'Varlık veya alt varlık'");
	ElsIf SearchForOperationalObjects Then
		Items.SearchResultRef.Title = NStr("vi = 'tài sản đang vận hành';
											|ru = 'Объект эксплуатации';
											|en = 'Asset'; fa = 'دارایی';
											|it = 'Oggetto di esercizio';
											|pl = 'Obiekt eksploatacji';
											|tr = 'Varlık'");
		Items.SearchResultRefType.Visible = False;
	Else
		Items.SearchResultRef.Title = NStr("vi = 'Chi tiết máy';
											|ru = 'Узел';
											|en = 'Sub-asset'; fa = 'زیردارایی';
											|it = 'Nodo';
											|pl = 'Węzeł';
											|tr = 'Alt varlık'");
		Items.SearchResultRefType.Visible = False;
	EndIf;
	
	ArrayOfBarcodes = NonCurrentAssets.ArrayOfBarcodes(Parameters.BarcodeData_5);
	If ArrayOfBarcodes.Count() <> 0 Then
		Barcode = ArrayOfBarcodes[0];
	EndIf;
	
	AddSearchResult(Parameters.ObjectsArray);
	
	If TypeOf(Parameters.PickingParameters) = Type("Structure") Then
		PickingParameters = New FixedStructure(Parameters.PickingParameters);
	Else
		PickingParameters = Undefined;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure RetrySearch(Command)
	RepeatServerSearch();
EndProcedure

&AtClient
Procedure CheckAll(Command)
	ChangeMark1(True);
EndProcedure

&AtClient
Procedure UncheckAll(Command)
	ChangeMark1(False);
EndProcedure

&AtClient
Procedure CompleteSelection(Command)
	
	SelectionResult = New Array;
	For Each RowData In SearchResult Do
		If RowData.Check Then
			SelectionResult.Add(RowData.Ref);
		EndIf;
	EndDo;

	Close(SelectionResult);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure ChangeMark1(Check)

	For Each RowData In SearchResult Do
		RowData.Check = Check;
	EndDo;
	
EndProcedure

&AtServer
Procedure RepeatServerSearch()
	
	SearchResult.Clear();
	
	If SearchForOperationalObjects Then
		Result = NonCurrentAssets.FindObjectsByBarcodes(
			CommonClientServer.ValueInArray(Barcode), 
			PickingParameters);
			
		AddSearchResult(Result.ObjectsArray);
	EndIf;
	If SearchForNodes Then
		Result = RMManagement.FindNodesByBarcodes(
			CommonClientServer.ValueInArray(Barcode), 
			PickingParameters);
			
		AddSearchResult(Result.ObjectsArray);
	EndIf;
EndProcedure

&AtServer
Procedure AddSearchResult(ObjectsArray)

	For Each ObjectRef In ObjectsArray Do
		NewRow = SearchResult.Add();
		NewRow.Check = True;
		NewRow.Ref = ObjectRef;
		NewRow.RefType = String(TypeOf(NewRow.Ref));
	EndDo;
	
EndProcedure

#EndRegion
