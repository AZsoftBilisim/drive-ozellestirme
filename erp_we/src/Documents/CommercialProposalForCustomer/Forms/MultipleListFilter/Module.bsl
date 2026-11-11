
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If IsBlankString(Title) Then
		Title = NStr("vi = 'Giá trị được chọn';
					|ru = 'Выбранные значения';
					|en = 'Selected values'; fa = 'مقادیر انتخاب‌شده';
					|it = 'Valori selezionati';
					|pl = 'Wybrane wartości';
					|tr = 'Seçilen değerler'");
	Else
		Title = Parameters.Title;
	EndIf;
	
	If TypeOf(Parameters.TypeOfEnumeration) <> Type("Type") Then
		Cancel = True;
		Return;
	EndIf;
	
	EnumerationMetadata = Metadata.FindByType(Parameters.TypeOfEnumeration);
	
	If Metadata.FindByType(Parameters.TypeOfEnumeration) = Undefined Then
		Cancel = True;
		Return;
	EndIf;
	
	For Each EnumerationValue In EnumerationMetadata.EnumValues Do
		
		ListItem = List.Add();
		
		ListItem.Value      = Enums[EnumerationMetadata.Name][EnumerationValue.Name];
		ListItem.Presentation = EnumerationValue.Synonym;
		
		If Parameters.SelectionList.FindByValue(ListItem.Value) <> Undefined Then
			
			ListItem.Check = True;
			
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	SelectedValues = New ValueList;
	
	For Each ListItem In List Do
		If ListItem.Check Then
			SelectedValues.Add(ListItem.Value);
		EndIf;
	EndDo;
	
	Close(SelectedValues);
	
EndProcedure

#EndRegion
