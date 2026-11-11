
#Region Variables

&AtClient
Var CurLineAdditionalData; // The current row of the table part is additional data.

#EndRegion

#Region FormEventHandlers

&AtClient
Procedure OnOpen(Cancel)
	
	Fields = CallbackDescriptionOnClose.AdditionalParameters.Fields;
	
	For Each CurField In Fields Do
		
		NewField = AdditionalData.Add();
		FillPropertyValues(NewField, CurField);
		NewField.Presentation = NewField.Value;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
    If Parameters.Property("AutoTest_2") Then
        Return;
    EndIf;
	
	If Parameters.Property("DCSStorageAddress") Then
		DCSStorageAddress = Parameters.DCSStorageAddress;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersAdditionalData

&AtClient
Procedure AdditionalDataSelection(Item, RowSelected, Field, StandardProcessing)
	
	SD = Items.AdditionalData.CurrentData;
	
	If SD<>Undefined Then
		StartEditingField(SD);
	EndIf;
	
EndProcedure

&AtClient
Procedure AdditionalDataOnActivateRow(Item)

	If CurLineAdditionalData<>Items.AdditionalData.CurrentRow Then
		
		CurLineAdditionalData = Items.AdditionalData.CurrentRow;
		SD = Items.AdditionalData.CurrentData;
		
		If SD<>Undefined Then
			
			Items.AdditionalDataChangeTheField.Enabled = True;
			Items.AdditionalDataRemoveField.Enabled = True;
			
		Else
			Items.AdditionalDataChangeTheField.Enabled = False;
			Items.AdditionalDataRemoveField.Enabled = False;
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure WriteAndClose(Command)
	
	CallbackDescriptionOnClose.AdditionalParameters.Fields.Clear();
	
	For Each CurField In AdditionalData Do
		
		DescriptionOfAdditionalDataField = New Structure;
		DescriptionOfAdditionalDataField.Insert("Description",			CurField.Description);
		DescriptionOfAdditionalDataField.Insert("Type",					CurField.Type);
		DescriptionOfAdditionalDataField.Insert("PopulationType",			CurField.PopulationType);
		DescriptionOfAdditionalDataField.Insert("DefaultValue",	CurField.DefaultValue);
		DescriptionOfAdditionalDataField.Insert("Value",				CurField.Value);
		DescriptionOfAdditionalDataField.Insert("Top",					Undefined);
		DescriptionOfAdditionalDataField.Insert("Left",					Undefined);
		DescriptionOfAdditionalDataField.Insert("Bottom",					Undefined);
		DescriptionOfAdditionalDataField.Insert("Right",					Undefined);
		DescriptionOfAdditionalDataField.Insert("Orientation",			Undefined);
		DescriptionOfAdditionalDataField.Insert("Font",					Undefined);
		DescriptionOfAdditionalDataField.Insert("LeftFrame",			Undefined);
		DescriptionOfAdditionalDataField.Insert("TopFrame",			Undefined);
		DescriptionOfAdditionalDataField.Insert("RightFrame",			Undefined);
		DescriptionOfAdditionalDataField.Insert("BottomFrame",			Undefined);
		DescriptionOfAdditionalDataField.Insert("BorderType",				Undefined);
		DescriptionOfAdditionalDataField.Insert("FrameWidth",			Undefined);
		DescriptionOfAdditionalDataField.Insert("BarcodeType",			Undefined);
		DescriptionOfAdditionalDataField.Insert("SignatureFontSize",	Undefined);
		DescriptionOfAdditionalDataField.Insert("BarcodeLabel",		Undefined);
		DescriptionOfAdditionalDataField.Insert("CheckCharacter",		Undefined);
		DescriptionOfAdditionalDataField.Insert("HorizontalPosition",Undefined);
		DescriptionOfAdditionalDataField.Insert("VerticalPosition",	Undefined);
		DescriptionOfAdditionalDataField.Insert("Multiline",		Undefined);
		DescriptionOfAdditionalDataField.Insert("Format",				CurField.Format);
			
		CallbackDescriptionOnClose.AdditionalParameters.Fields.Add(DescriptionOfAdditionalDataField);
		
	EndDo;
	
	Close(DialogReturnCode.OK);
	
EndProcedure

&AtClient
Procedure AddAField(Command)
	
	StartAddingField();
	
EndProcedure

&AtClient
Procedure ChangeTheField(Command)
	
	SD = Items.AdditionalData.CurrentData;
	
	If SD<>Undefined Then
		StartEditingField(SD);
	EndIf;
	
EndProcedure

&AtClient
Procedure RemoveField(Command)
	
	SD = Items.AdditionalData.CurrentData;
	
	If SD<>Undefined Then
		
		AdditionalData.Delete(SD);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure StartAddingField()
	
	FieldDetails = New Structure;
	FieldDetails.Insert("Description", String(New UUID));
	FieldDetails.Insert("Top", 0);
	FieldDetails.Insert("Left", 0);
	FieldDetails.Insert("Bottom", 0);
	FieldDetails.Insert("Right", 0);
	
	FieldDetails.Insert("PopulationType", "Parameter");
	
	TransmittedParameters = New Structure;
	TransmittedParameters.Insert("FieldDetails", FieldDetails);
	TransmittedParameters.Insert("EditingAdvancedField", True);
	TransmittedParameters.Insert("GridStep", GridStep);
	
	NotificationOnCompletion = New CallbackDescription("StartAddingEditingCompletionField", ThisObject, TransmittedParameters);
	OpenForm("Catalog.TemplatesOfPLLabelsAndPriceTags.Form.LabelEditorFormOfTemplateFieldEditing", New Structure("DCSStorageAddress", DCSStorageAddress),,,,, NotificationOnCompletion);
	
EndProcedure

&AtClient
Procedure StartEditingField(Field)
	
	FieldDetails = New Structure;
	FieldDetails.Insert("Description",			Field.Description);
	FieldDetails.Insert("Type",					Field.Type);
	FieldDetails.Insert("PopulationType",			Field.PopulationType);
	FieldDetails.Insert("DefaultValue",	Field.DefaultValue);
	FieldDetails.Insert("Value",				Field.Value);
	FieldDetails.Insert("Top",					?(ValueIsFilled(Field.Top), Field.Top, 1));
	FieldDetails.Insert("Left",					?(ValueIsFilled(Field.Left), Field.Left, 1));
	FieldDetails.Insert("Bottom",					?(ValueIsFilled(Field.Bottom), Field.Bottom, 1));
	FieldDetails.Insert("Right",					?(ValueIsFilled(Field.Right), Field.Right, 1));
	FieldDetails.Insert("Orientation",				Field.Orientation);
	FieldDetails.Insert("Font",					New Font(Field.FontName, ?(ValueIsFilled(Field.FontSize), Field.FontSize, Undefined), Field.Fatty, Field.Italic, Field.Underline, Field.Strikeout));
	FieldDetails.Insert("LeftFrame",				Field.LeftFrame);
	FieldDetails.Insert("TopFrame",			Field.TopFrame);
	FieldDetails.Insert("RightFrame",			Field.RightFrame);
	FieldDetails.Insert("BottomFrame",				Field.BottomFrame);
	FieldDetails.Insert("BorderType",				?(ValueIsFilled(Field.BorderType), Field.BorderType, "Solid"));
	FieldDetails.Insert("FrameWidth",			?(ValueIsFilled(Field.FrameWidth), Field.FrameWidth, 1));
	FieldDetails.Insert("BarcodeType",			?(ValueIsFilled(Field.BarcodeType), Field.BarcodeType, "EAN8"));
	FieldDetails.Insert("SignatureFontSize",	?(ValueIsFilled(Field.SignatureFontSize), Field.SignatureFontSize, 3));
	FieldDetails.Insert("BarcodeLabel",		Field.BarcodeLabel);
	FieldDetails.Insert("CheckCharacter",		Field.CheckCharacter);
	FieldDetails.Insert("HorizontalPosition",	?(ValueIsFilled(Field.HorizontalPosition), Field.HorizontalPosition, "Left"));
	FieldDetails.Insert("VerticalPosition",	?(ValueIsFilled(Field.VerticalPosition), Field.VerticalPosition, "Top"));
	FieldDetails.Insert("Multiline",		Field.Multiline);
	FieldDetails.Insert("Format",					Field.Format);
	
	FieldToEdit = New Structure;
	FieldToEdit.Insert("Description",	Field.Description);
	FieldToEdit.Insert("Type",			Field.Type);
	FieldToEdit.Insert("Top",			Field.Top);
	FieldToEdit.Insert("Left",			Field.Left);
	FieldToEdit.Insert("Bottom",			Field.Bottom);
	FieldToEdit.Insert("Right",			Field.Right);
	
	TransmittedParameters = New Structure;
	TransmittedParameters.Insert("FieldDetails", FieldDetails);
	TransmittedParameters.Insert("FieldToEdit", FieldToEdit);
	TransmittedParameters.Insert("EditingAdvancedField", True);
	TransmittedParameters.Insert("GridStep", GridStep);
	
	NotificationOnCompletion = New CallbackDescription("StartAddingEditingCompletionField", ThisObject, TransmittedParameters);
	OpenForm("Catalog.TemplatesOfPLLabelsAndPriceTags.Form.LabelEditorFormOfTemplateFieldEditing", New Structure("DCSStorageAddress", DCSStorageAddress),,,,, NotificationOnCompletion);
	
EndProcedure

&AtClient
Procedure StartAddingEditingCompletionField(Result, TransmittedParameters) Export
	
	If Result = DialogReturnCode.OK Then
		
		
		If TransmittedParameters.Property("FieldToEdit") Then
			FieldToEdit = TransmittedParameters.FieldToEdit;
		Else
			FieldToEdit = Undefined;
		EndIf;
		FieldDetails = TransmittedParameters.FieldDetails;
		
		SaveFieldDescription(FieldDetails, FieldToEdit);
		
	EndIf;	
	
EndProcedure

// LongDesc
// 
// Parameters:
// 	FieldDetails - Structure - structure with fields:
// 	*Description - String - .
// 	FieldToEdit - Structure - structure with fields:
// 	*Description - String - .
// 	*Type - String - .
// 	*Top - String - .
// 	*Left - String - .
// 	*Bottom - String - .
// 	*Right - String - .
&AtClient
Procedure SaveFieldDescription(FieldDetails, FieldToEdit=Undefined)
	
	If FieldToEdit<>Undefined Then
		TemplateField = AdditionalData.FindRows(New Structure("Description", FieldToEdit.Description))[0];
	Else
		TemplateField	= AdditionalData.Add();
	EndIf;
	
	TemplateField.Type	= FieldDetails.Type;
	TemplateField.Description	= FieldDetails.Description;
	TemplateField.Value = FieldDetails.Value;
	TemplateField.PopulationType = FieldDetails.PopulationType;
	TemplateField.Value = FieldDetails.Value;
	TemplateField.DefaultValue = FieldDetails.DefaultValue;
	
	TemplateField.Presentation				= FieldDetails.Value;
	TemplateField.Format						= FieldDetails.Format;
	TemplateField.Top							= Undefined;
	TemplateField.Left							= Undefined;
	TemplateField.Bottom							= Undefined;
	TemplateField.Right						= Undefined;
	TemplateField.Orientation					= Undefined;
	TemplateField.FontName					= Undefined;
	TemplateField.FontSize					= Undefined;
	TemplateField.Fatty						= Undefined;
	TemplateField.Italic					= Undefined;
	TemplateField.Underline				= Undefined;
	TemplateField.Strikeout					= Undefined;
	TemplateField.LeftFrame					= Undefined;
	TemplateField.TopFrame					= Undefined;
	TemplateField.RightFrame					= Undefined;
	TemplateField.BottomFrame					= Undefined;
	TemplateField.BorderType						= Undefined;
	TemplateField.FrameWidth					= Undefined;
	TemplateField.HorizontalPosition		= Undefined;
	TemplateField.VerticalPosition			= Undefined;
	TemplateField.Multiline				= Undefined;
	TemplateField.BarcodeType					= Undefined;
	TemplateField.CheckCharacter			= Undefined;
	TemplateField.BarcodeLabel				= Undefined;
	TemplateField.SignatureFontSize			= Undefined;
	
EndProcedure

#EndRegion