#Region Variables

&AtClient
Var CachedValues;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ConfigureDependentFormElements(ThisObject);
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Modified Then
		StandardProcessing = False;
		Cancel = True;
		QueryText = NStr("vi = 'Dữ liệu đã thay đổi. Lưu thay đổi?';
						|ru = 'Данные были изменены. Сохранить изменения?';
						|en = 'The data was changed. Do you want to save the changes?'; fa = 'The data was changed. Do you want to save the changes?';
						|it = 'I dati sono stati modificati. Salvare le modifiche?';
						|pl = 'Dane zostały zmienione. Chcesz zapisać zmiany?';
						|tr = 'Veriler değiştirildi. Değişiklikler kaydedilsin mi?'");
		CallbackDescription = New CallbackDescription("BeforeCloseCompletion", ThisObject);
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNoCancel);
	EndIf;
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	If Not ItemVariantsAreUsed Then
		NotCheckedAttributeArray.Add("Characteristic");
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ProductsOnChange(Item)
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("CheckCharacteristicsByOwner", Characteristic);
	
	BatchProcessingOfTablePartClient.ProcessTSString(ThisObject, StructureOfActions, CachedValues);
	
	ConfigureDependentFormElements(ThisObject, "Products");
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Save(Command)
	
	CompleteEditing();
	
EndProcedure

#EndRegion

#Region Private

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElements(Form, AttributesList = "")
	
	Items = Form.Items;
	
	Initialize = IsBlankString(AttributesList);
	AttributesStructure1 = New Structure(AttributesList);
	
	If AttributesStructure1.Property("Products")
		Or Initialize Then
			
			Items.Characteristic.ReadOnly = Not Form.ItemVariantsAreUsed;
			Items.Characteristic.AutoMarkIncomplete = Form.ItemVariantsAreUsed;
			Items.Characteristic.InputHint = ?(Form.ItemVariantsAreUsed, "", NStr("vi = '<không sử dụng đặc tính>';
																					|ru = '<характеристики не используются>';
																					|en = '<variants are not used>'; fa = '<گونه‌ها استفاده نمی‌شوند>';
																					|it = '<le caratteristiche non vengono usate>';
																					|pl = '<charakterystyki nie dotyczą>';
																					|tr = '<varyantlar kullanılmamaktadır>'"));
			
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeCloseCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		CompleteEditing();
	ElsIf QuestionResult = DialogReturnCode.No Then
		Modified = False;
		Close();
	EndIf;
	
EndProcedure

&AtClient
Procedure CompleteEditing()
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	Modified = False;
	
	Close(New Structure("Products,Characteristic", Products,Characteristic));
	
EndProcedure

#EndRegion