

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Not Parameters.Property("AdditionalFields")
	 Or Not Parameters.Property("ValueType")
	 Or Not Parameters.Property("TheseAreLines") Then
		MessageText = NStr("vi = 'Không xem xét mở trực tiếp biểu mẫu này.';
							|ru = 'Непосредственное открытие этой формы не предусмотрено.';
							|en = 'Application cannot open this form explicitly.'; fa = 'Application cannot open this form explicitly.';
							|it = 'L''apertura diretta di questo modulo non è prevista.';
							|pl = 'Bezpośrednie otwieranie tego formularza nie jest przewidziane.';
							|tr = 'Bu formun doğrudan açılması sağlanamadı.'");
		Raise MessageText;
	EndIf;
	
	ValueType = Parameters.ValueType;
	SelectedFields.Load(GetFromTempStorage(Parameters.AdditionalFields));
	
	Items.SelectedFieldsInSeparateColumn.Visible = Parameters.TheseAreLines;
	
	DCS = DataCompositionServer.EmptyCircuit();
	Set = DataCompositionServer.AddEmptyDataSet(DCS, Type("DataCompositionSchemaDataSetObject"));
	FieldTitle = NStr("vi = 'Tham chiếu';
						|ru = 'Ссылка';
						|en = 'Reference'; fa = 'مرجع';
						|it = 'Link';
						|pl = 'Odnośnik';
						|tr = 'Bağlantı'");
	FinancialReportingServer.NewSetField(Set, "Ref", "Ref", FieldTitle, ValueType);
	
	Composer = FinancialReportingServer.SchemaComposer(DCS);
	LinkFields_ = Composer.Settings.SelectionAvailableFields.Items[0].Items;
	
	FirstChar = StrLen("Ref.") + 1;
	
	AttributesToSkip1 = "DeletionMark, DataVersion, IsFolder, Predefined,
	                        |PredefinedDataName";
	AttributesToSkip1 = StringFunctionsClientServer.SplitStringIntoSubstringsArray(AttributesToSkip1,,,True);
	
	For Each AvailableField In LinkFields_ Do
		If AvailableField.Table Then
			Continue;
		EndIf;
		AttributeName = Mid(AvailableField.Field, FirstChar);
		If AttributesToSkip1.Find(AttributeName) <> Undefined Then
			Continue;
		EndIf;
		If SelectedFields.FindRows(New Structure("Attribute", AttributeName)).Count() Then
			Continue;
		EndIf;
		NewRow = AvailableFields.Add();
		NewRow.Attribute = AttributeName;
		NewRow.Description = Mid(AvailableField.Title, FirstChar);
	EndDo;
	
	AvailableFields.Sort("Description");
	
EndProcedure

#EndRegion

#Region TableEventHandlersForms

&AtClient
Procedure AvailableFieldsSelection(Item, RowSelected, Field, StandardProcessing)
	
	MoveToRight(Undefined);
	
EndProcedure

&AtClient
Procedure SelectedFieldsSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Item.CurrentItem.Name = "AdditionalFieldsOfTheHeader" Then
		Return;
	EndIf;
	
	If Item.CurrentItem.Name = "SelectedFieldsInSeparateColumn" Then
		Return;
	EndIf;
	
	MoveLeft(Undefined);
	
EndProcedure

&AtClient
Procedure Select(Command)
	
	Close(PutResultInStorage());
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure MoveToRight(Command)
	
	CurrentData = Items.AvailableFields.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	NewRow = SelectedFields.Add();
	FillPropertyValues(NewRow, CurrentData);
	Items.SelectedFields.CurrentRow = NewRow.GetID();
	
	AvailableFields.Delete(CurrentData);
	
EndProcedure

&AtClient
Procedure MoveLeft(Command)
	
	CurrentData = Items.SelectedFields.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	NewRow = AvailableFields.Add();
	FillPropertyValues(NewRow, CurrentData);
	Items.AvailableFields.CurrentRow = NewRow.GetID();
	AvailableFields.Sort("Description");
	
	SelectedFields.Delete(CurrentData);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function PutResultInStorage()
	
	Return PutToTempStorage(SelectedFields.Unload());
	
EndFunction

#EndRegion

