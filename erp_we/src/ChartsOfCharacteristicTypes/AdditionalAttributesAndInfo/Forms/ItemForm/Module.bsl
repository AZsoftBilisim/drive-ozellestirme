///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Variables

&AtClient
Var ProcessingEndOfRecording, ContinuationHandlerOnWriteError, CancelOnWrite;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	NewPassedParametersStructure();
	
	If PassedFormParameters.SelectSharedProperty
		Or PassedFormParameters.SelectAdditionalValuesOwner
		Or PassedFormParameters.CopyWithQuestion Then
		WindowOpeningMode = FormWindowOpeningMode.LockOwnerWindow;
		WizardMode               = True;
		If PassedFormParameters.CopyWithQuestion Then
			Items.WIzardCardPages.CurrentPage = Items.ActionChoice;
			FillActionListOnAddAttribute();
		Else
			FillChoicePage();
		EndIf;
		RefreshFormItemsContent();
		
		If Common.IsWebClient() Then
			Items.AttributeCard.Visible = False;
		EndIf;
	Else
		FillPropertyCard();
		// Object attribute lock subsystem handler.
		ObjectAttributesLock.LockAttributes(ThisObject);
	EndIf;
	
	If Not Common.SubsystemExists("StandardSubsystems.DuplicateObjectsDetection") Then
		Items.FormDuplicateObjectsDetection.Visible = False;
	EndIf;
	
	Items.MultilineGroup.Representation          = UsualGroupRepresentation.NormalSeparation;
	If Not PropertyManagerInternal.ValueTypeContainsPropertyValues(Object.ValueType) Then
		Items.PropertiesAndDependenciesGroup.Representation = UsualGroupRepresentation.NormalSeparation;
		Items.OtherAttributes.Representation         = UsualGroupRepresentation.NormalSeparation;
	EndIf;
	
	If Common.IsMobileClient() Then
		Items.PropertiesSets.InitialTreeView = InitialTreeView.ExpandAllLevels;
		Items.AdditionalInformationGroup.Representation = UsualGroupRepresentation.NormalSeparation;
		Items.Close.Visible = False;
		Items.AttributeDescriptionGroup.ItemsAndTitlesAlign = ItemsAndTitlesAlignVariant.ItemsRightTitlesLeft;
		Items.AttributeValueType.ItemsAndTitlesAlign        = ItemsAndTitlesAlignVariant.ItemsRightTitlesLeft;
	EndIf;
	
	Items.FillIDForFormulas.Enabled = Not Items.IDForFormulas.ReadOnly;
	
	If Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
		ModuleNationalLanguageSupportServer = Common.CommonModule("NationalLanguageSupportServer");
		ModuleNationalLanguageSupportServer.OnCreateAtServer(ThisObject, Object);
	EndIf;
	
	CurrentTitle = Object.Title;
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If TypeOf(ValueSelected) = Type("ChartOfCharacteristicTypesRef.AdditionalAttributesAndInfo") Then
		Close();
		
		// Open the property form.
		FormParameters = New Structure;
		FormParameters.Insert("Key", ValueSelected);
		FormParameters.Insert("CurrentPropertiesSet", CurrentPropertiesSet);
		
		OpenForm("ChartOfCharacteristicTypes.AdditionalAttributesAndInfo.ObjectForm",
			FormParameters, FormOwner);
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	If Not WriteParameters.Property("DescriptionChangeConfirmed") Then
		If ValueIsFilled(CurrentTitle) And CurrentTitle <> Object.Title Then
			QueryText = NStr("vi = 'Tên đã được thay đổi. Cần phải cài đặt lại việc hiển thị
				                      | thuộc tính bổ sung trong danh sách và báo cáo, cũng như việc sử dụng
				                      | trong bộ lọc.';
				                      |ru = 'Наименование было изменено. Потребуется заново настроить отображение
				                      |дополнительного реквизита в списках и отчетах, а также использование
				                      |в отборах.';
				                      |en = 'If you change the attribute''s description, you have to configure its view
				                      |in all of the lists, reports, and filters
				                      |that include the attribute.'; fa = 'If you change the attribute''s description, you have to configure its view
				                      |in all of the lists, reports, and filters
				                      |that include the attribute.';
				                      |it = 'Il nome è stato modificato. La visualizzazione
				                      |del requisto aggiuntivo negli elenchi e report, nonché utilizzo
				                      | nelle selezioni, dovranno essere reimpostati.';
				                      |pl = 'Nazwa została zmieniona. Trzeba będzie ponownie ustawić wyświetlenie 
				                      |dodatkowego atrybutu w listach i raportach oraz użytkowanie 
				                      |w filtrach.';
				                      |tr = 'İsim değiştirildi. Listelerde ve raporlarda ek özniteliğin görüntülenmesini
				                      |ve seçimlerde kullanımını
				                      |yeniden yapılandırmak gerekecektir.'");
			QueryText = StrReplace(QueryText, Chars.LF, " ");
			
			Buttons = New ValueList;
			Buttons.Add("ContinueWrite",            NStr("vi = 'Đổi tên';
														|ru = 'Переименовать';
														|en = 'Rename'; fa = 'تغییر نام';
														|it = 'Rinominare';
														|pl = 'Rename';
														|tr = 'Yeniden adlandır'"));
			Buttons.Add("ReturnDescription", NStr("vi = 'Hủy bỏ';
													|ru = 'Отмена';
													|en = 'Cancel'; fa = 'انصراف';
													|it = 'Annulla';
													|pl = 'Anuluj';
													|tr = 'İptal'"));
			
			CancelOnWrite = True;
			Cancel = True;
			
			ShowQueryBox(
				New CallbackDescription("AfterResponseToDescriptionChangeQuestion", ThisObject, WriteParameters),
				QueryText, Buttons, , "ReturnDescription");
			Return;
		EndIf;
	EndIf;
	
	If Not WriteParameters.Property("WhenDescriptionAlreadyInUse") Then
	
		// Fill the description from the property set and check if
		// there's a property with the same description.
		If CommonClient.SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
			QueryText = DescriptionAlreadyUsed(
				Object.Title, Object.Ref, CurrentPropertiesSet, Object.Description, Object.TitleLanguage1, Object.TitleLanguage2);
		Else
			QueryText = DescriptionAlreadyUsed(
				Object.Title, Object.Ref, CurrentPropertiesSet, Object.Description, "", "");
		EndIf;
		
		If ValueIsFilled(QueryText) Then
			Buttons = New ValueList;
			Buttons.Add("ContinueWrite",            NStr("vi = 'Tiếp tục ghi';
														|ru = 'Продолжить запись';
														|en = 'Save'; fa = 'ذخیره';
														|it = 'Continuare la scrittura';
														|pl = 'Kontynuuj zapis';
														|tr = 'Yazmaya devam et'"));
			Buttons.Add("BackToDescriptionInput", NStr("vi = 'Quay lại để nhập tên gọi';
														|ru = 'Вернуться к вводу наименования';
														|en = 'Edit description'; fa = 'Edit description';
														|it = 'Ritornare all''immissione del nome';
														|pl = 'Wróć do wprowadzania nazwy';
														|tr = 'İsim girişine dön'"));
			
			CancelOnWrite = True;
			Cancel = True;
			
			ShowQueryBox(
				New CallbackDescription("AfterResponseOnQuestionWhenDescriptionIsAlreadyUsed", ThisObject, WriteParameters),
				QueryText, Buttons, , "BackToDescriptionInput");
			Return;
		EndIf;
	EndIf;
	
	If Not WriteParameters.Property("WhenNameAlreadyInUse")
		And ValueIsFilled(Object.Name) Then
		// Check whether there is a property with the same name.
		QueryText = NameAlreadyUsed(
			Object.Name, Object.Ref, Object.Description);
		
		If ValueIsFilled(QueryText) Then
			Buttons = New ValueList;
			Buttons.Add("ContinueWrite",            NStr("vi = 'Tiếp tục';
														|ru = 'Продолжить';
														|en = 'Continue'; fa = 'ادامه';
														|it = 'Continuare';
														|pl = 'Kontynuuj';
														|tr = 'Devam et'"));
			Buttons.Add("BackToNameInput", NStr("vi = 'Hủy bỏ';
												|ru = 'Отмена';
												|en = 'Cancel'; fa = 'انصراف';
												|it = 'Annulla';
												|pl = 'Anuluj';
												|tr = 'İptal'"));
			
			CancelOnWrite = True;
			Cancel = True;
			ShowQueryBox(
				New CallbackDescription("AfterResponseOnQuestionWhenNameIsAlreadyUsed", ThisObject, WriteParameters),
				QueryText, Buttons, , "ContinueWrite");
			Return;
		EndIf;
	EndIf;
	
	If Not WriteParameters.Property("WhenIDForFormulasIsAlreadyUsed")
		And ValueIsFilled(Object.IDForFormulas) Then
		// Fill formula ID and check if there's a property with the same ID.
		// 
		QueryText = IDForFormulasAlreadyUsed(
			Object.IDForFormulas, Object.Ref);
		
		If ValueIsFilled(QueryText) Then
			Buttons = New ValueList;
			Buttons.Add("ContinueWrite",              NStr("vi = 'Tiếp tục';
															|ru = 'Продолжить';
															|en = 'Continue'; fa = 'ادامه';
															|it = 'Continuare';
															|pl = 'Kontynuuj';
															|tr = 'Devam et'"));
			Buttons.Add("BackToIDInput", NStr("vi = 'Hủy bỏ';
												|ru = 'Отмена';
												|en = 'Cancel'; fa = 'انصراف';
												|it = 'Annulla';
												|pl = 'Anuluj';
												|tr = 'İptal'"));
			
			CancelOnWrite = True;
			Cancel = True;
			
			ShowQueryBox(
				New CallbackDescription("AfterResponseOnQuestionWhenIDForFormulasIsAlreadyUsed", ThisObject, WriteParameters),
				QueryText, Buttons, , "ContinueWrite");
			Return;
			
		Else
			WriteParameters.Insert("IDCheckForFormulasCompleted");
		EndIf;
	EndIf;
	
	FillMultilingualRequisites();
	
	If WriteParameters.Property("ContinuationHandler") Then
		ContinuationHandlerOnWriteError = WriteParameters.ContinuationHandler;
		AttachIdleHandler("AfterWriteError", 0.1, True);
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If PropertyManagerInternal.ValueTypeContainsPropertyValues(Object.ValueType) Then
		CurrentObject.AdditionalValuesUsed = True;
	Else
		CurrentObject.AdditionalValuesUsed = False;
		CurrentObject.ValueFormTitle = "";
		CurrentObject.ValueChoiceFormTitle = "";
	EndIf;
	
	If Object.IsAdditionalInfo
	 Or Not (    Object.ValueType.ContainsType(Type("Number" ))
	         Or Object.ValueType.ContainsType(Type("Date"  ))
	         Or Object.ValueType.ContainsType(Type("Boolean")) )Then
		
		CurrentObject.FormatProperties = "";
	EndIf;
	
	CurrentObject.MultilineInputField = 0;
	
	If Not Object.IsAdditionalInfo
	   And Object.ValueType.Types().Count() = 1
	   And Object.ValueType.ContainsType(Type("String")) Then
		
		If AttributeRepresentation = "MultilineInputField" Then
			CurrentObject.MultilineInputField   = MultilineInputFieldNumber;
			CurrentObject.OutputAsHyperlink = False;
		EndIf;
	EndIf;
	
	// Generating additional attribute or info name.
	If Not ValueIsFilled(CurrentObject.Name)
		Or WriteParameters.Property("WhenNameAlreadyInUse") Then
		CurrentObject.Name = "";
		ObjectTitle = CurrentObject.Title;
		PropertyManagerInternal.DeleteDisallowedCharacters(ObjectTitle);
		ObjectTitleInParts = StrSplit(ObjectTitle, " ", False);
		For Each TitlePart In ObjectTitleInParts Do
			CurrentObject.Name = CurrentObject.Name + Upper(Left(TitlePart, 1)) + Mid(TitlePart, 2);
		EndDo;
		
		If PropertyManagerInternal.TheNameStartsWithANumber(CurrentObject.Name) Then
			CurrentObject.Name = "_" + CurrentObject.Name;
		EndIf;
		
		UID = New UUID();
		UIDString = StrReplace(String(UID), "-", "");
		CurrentObject.Name = CurrentObject.Name + "_" + UIDString;
	EndIf;
	
	// Generate ID for additional attribute (information record) formulas.
	If Not ValueIsFilled(CurrentObject.IDForFormulas)
		Or WriteParameters.Property("WhenIDForFormulasIsAlreadyUsed") Then
			
		ObjectTitle = CurrentObject.Title;
		If Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
			ModuleNationalLanguageSupportServer = Common.CommonModule("NationalLanguageSupportServer");
			CurrentLanguageSuffix = ModuleNationalLanguageSupportServer.CurrentLanguageSuffix();
			If ValueIsFilled(CurrentLanguageSuffix) And ValueIsFilled(CurrentObject["Title" + CurrentLanguageSuffix]) Then
				ObjectTitle = CurrentObject["Title" + CurrentLanguageSuffix];
			EndIf;
		EndIf;
		
		CurrentObject.IDForFormulas = ChartsOfCharacteristicTypes.AdditionalAttributesAndInfo.UUIDForFormulas(
			ObjectTitle, CurrentObject.Ref);
		
		WriteParameters.Insert("IDCheckForFormulasCompleted");
	EndIf;
	If WriteParameters.Property("IDCheckForFormulasCompleted") Then
		CurrentObject.AdditionalProperties.Insert("IDCheckForFormulasCompleted");
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
		ModuleNationalLanguageSupportServer = Common.CommonModule("NationalLanguageSupportServer");
		ModuleNationalLanguageSupportServer.BeforeWriteAtServer(CurrentObject);
	EndIf;
	
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If ValueIsFilled(CurrentPropertiesSet) Then
		
		Block = New DataLock;
		LockItem = Block.Add("Catalog.AdditionalAttributesAndInfoSets");
		LockItem.SetValue("Ref", CurrentPropertiesSet);
		Block.Lock();
		LockDataForEdit(CurrentPropertiesSet);
		
		ObjectPropertySet = CurrentPropertiesSet.GetObject();
		If CurrentObject.IsAdditionalInfo Then
			TabularSection = ObjectPropertySet.AdditionalInfo;
		Else
			TabularSection = ObjectPropertySet.AdditionalAttributes;
		EndIf;
		FoundRow = TabularSection.Find(CurrentObject.Ref, "Property");
		If FoundRow = Undefined Then
			NewRow = TabularSection.Add();
			NewRow.Property = CurrentObject.Ref;
			ObjectPropertySet.Write();
			CurrentObject.AdditionalProperties.Insert("ChangedSet", CurrentPropertiesSet);
		EndIf;
		
	EndIf;
	
	If WriteParameters.Property("ClearEnteredWeightCoefficients") Then
		ClearEnteredWeightCoefficients();
	EndIf;
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	EndIf;
	// End StandardSubsystems.AccessManagement
	
	If AttributeAddMode = "CreateByCopying" Then
		WriteAdditionalAttributeValuesOnCopy(CurrentObject);
	EndIf;
	
	// Object attribute lock subsystem handler.
	ObjectAttributesLock.LockAttributes(ThisObject);
	
	If Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
		ModuleNationalLanguageSupportServer = Common.CommonModule("NationalLanguageSupportServer");
		ModuleNationalLanguageSupportServer.OnReadAtServer(ThisObject, CurrentObject);
	EndIf;
	
	RefreshFormItemsContent();
	
	If CurrentObject.AdditionalProperties.Property("ChangedSet") Then
		WriteParameters.Insert("ChangedSet", CurrentObject.AdditionalProperties.ChangedSet);
	EndIf;
	
	CurrentTitle = Object.Title;
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_AdditionalAttributesAndInfo",
		New Structure("Ref", Object.Ref), Object.Ref);
	
	If WriteParameters.Property("ChangedSet") Then
		
		Notify("Write_AdditionalAttributesAndInfoSets",
			New Structure("Ref", WriteParameters.ChangedSet), WriteParameters.ChangedSet);
	EndIf;
	
	If WriteParameters.Property("ContinuationHandler") Then
		ContinuationHandlerOnWriteError = Undefined;
		DetachIdleHandler("AfterWriteError");
		RunCallback(
			New CallbackDescription(WriteParameters.ContinuationHandler.ProcedureName,
				ThisObject, WriteParameters.ContinuationHandler.Parameters),
			False);
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	If WizardMode Then
		SetWizardSettings();
	EndIf;
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	If EventName = "PropertiesAttributeDependencySet" Then
		Modified = True;
		ValueAdded = False;
		For Each DependenceCondition In AttributeDependencyConditions Do
			Value = Undefined;
			If Parameter.Property(DependenceCondition.Presentation, Value) Then
				ValueInStorage = PutToTempStorage(Value, UUID);
				DependenceCondition.Value = ValueInStorage;
				ValueAdded = True;
			EndIf;
		EndDo;
		If Not ValueAdded Then
			For Each PassedParameter In Parameter Do
				ValueInStorage = PutToTempStorage(PassedParameter.Value, UUID);
				AttributeDependencyConditions.Add(ValueInStorage, PassedParameter.Key);
			EndDo;
		EndIf;
		
		SetAdditionalAttributeDependencies();
	EndIf;
	
	If EventName = "AfterInputStringsInDifferentLanguages"
		And Parameter = ThisObject Then
		If Not ValueIsFilled(Object.Ref) Then
			UpdateSuggestedIDValue();
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	EndIf;
	// End StandardSubsystems.AccessManagement
	
	If Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
		ModuleNationalLanguageSupportServer = Common.CommonModule("NationalLanguageSupportServer");
		ModuleNationalLanguageSupportServer.OnReadAtServer(ThisObject, CurrentObject);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PropertyKindOnChange(Item)
	
	Object.PropertyKind1 = PropertyKind1;
	If Object.PropertyKind1 = PredefinedValue("Enum.PropertiesKinds.AdditionalInfo") Then
		Object.IsAdditionalInfo = True;
	EndIf;
	
	RefreshFormItemsContent();
	
EndProcedure

&AtClient
Procedure ValueListAdjustmentCommentClick(Item)
	
	FollowUpHandler = New CallbackDescription("ValueListAdjustmentCommentClickCompletion", ThisObject);
	WriteObject("GoToValueList", FollowUpHandler);
	
EndProcedure

&AtClient
Procedure SetsAdjustmentCommentClick(Item)
	
	FollowUpHandler = New CallbackDescription("SetsAdjustmentCommentClickContinued", ThisObject);
	WriteObject("GoToValueList", FollowUpHandler);
	
EndProcedure

&AtClient
Procedure ValueTypeOnChange(Item)
	
	WarningText = "";
	RefreshFormItemsContent(WarningText);
	
	If ValueIsFilled(WarningText) Then
		ShowMessageBox(, WarningText);
	EndIf;
	
EndProcedure

&AtClient
Procedure AdditionalValuesWithWeightOnChange(Item)
	
	If ValueIsFilled(Object.Ref)
	   And Not Object.AdditionalValuesWithWeight Then
		
		QueryText =
			NStr("vi = 'Xóa các hệ số trọng số đã nhập?
			           |
			           |Dữ liệu sẽ được ghi.';
			           |ru = 'Очистить введенные весовые коэффициенты?
			           |
			           |Данные будут записаны.';
			           |en = 'Do you want to clear the weight coefficients?
			           |
			           |The data will be saved.'; fa = 'Do you want to clear the weight coefficients?
			           |
			           |The data will be saved.';
			           |it = 'Cancellare i coefficienti di peso inseriti?
			           |
			           |I dati verranno registrati.';
			           |pl = 'Oczyścić wprowadzone współczynniki wagowe?
			           |
			           |Dane zostaną zapisane.';
			           |tr = 'Girilen ağırlık katsayıları temizlensin mi? 
			           |
			           |Veri yazılacak.'");
		
		Buttons = New ValueList;
		Buttons.Add("ClearAndWrite", NStr("vi = 'Xóa bỏ và ghi lại';
											|ru = 'Очистить и записать';
											|en = 'Clear and save'; fa = 'Clear and save';
											|it = 'Cancellare e registrare';
											|pl = 'Oczyść i zapisz';
											|tr = 'Temizle ve yaz'"));
		Buttons.Add("Cancel", NStr("vi = 'Hủy bỏ';
									|ru = 'Отмена';
									|en = 'Cancel'; fa = 'انصراف';
									|it = 'Annulla';
									|pl = 'Cancel';
									|tr = 'İptal'"));
		
		ShowQueryBox(
			New CallbackDescription("AfterConfirmClearWeightCoefficients", ThisObject),
			QueryText, Buttons, , "ClearAndWrite");
	Else
		QueryText = NStr("vi = 'Dữ liệu sẽ được ghi lại.';
						|ru = 'Данные будут записаны.';
						|en = 'Do you want to save the data?'; fa = 'Do you want to save the data?';
						|it = 'I dati verranno registrati.';
						|pl = 'Dane zostaną zapisane.';
						|tr = 'Veriler yazılacaktır.'");
		
		Buttons = New ValueList;
		Buttons.Add("Write", NStr("vi = 'Ghi lại';
									|ru = 'Записать';
									|en = 'Save'; fa = 'ذخیره';
									|it = 'Salvare';
									|pl = 'Save';
									|tr = 'Kaydet'"));
		Buttons.Add("Cancel", NStr("vi = 'Hủy bỏ';
									|ru = 'Отмена';
									|en = 'Cancel'; fa = 'انصراف';
									|it = 'Annulla';
									|pl = 'Cancel';
									|tr = 'İptal'"));
		
		ShowQueryBox(
			New CallbackDescription("AfterConfirmEnableWeightCoefficients", ThisObject),
			QueryText, Buttons, , "Write");
	EndIf;
	
EndProcedure

&AtClient
Procedure MultilineInputFieldNumberOnChange(Item)
	
	AttributeRepresentation = "MultilineInputField";
	
EndProcedure

&AtClient
Procedure CommentOpening(Item, StandardProcessing)
	
	StandardProcessing = False;
	CommonClient.ShowCommentEditingForm(Item.EditText, ThisObject);
	
EndProcedure

&AtClient
Procedure RequiredToFillOnChange(Item)
	Items.ChooseItemRequiredOption.Enabled = Object.RequiredToFill;
EndProcedure

&AtClient
Procedure ChooseAvailabilityOptionClick(Item)
	OpenDependenceSettingForm("Available");
EndProcedure

&AtClient
Procedure SetConditionClick(Item)
	OpenDependenceSettingForm("RequiredToFill");
EndProcedure

&AtClient
Procedure ChooseVisibilityOptionClick(Item)
	OpenDependenceSettingForm("isVisible");
EndProcedure

&AtClient
Procedure CommentStartChoice(Item, ChoiceData, StandardProcessing)
	CommonClient.ShowCommentEditingForm(Item.EditText, ThisObject);
EndProcedure

&AtClient
Procedure AttributeKindOnChange(Item)
	Items.OutputAsHyperlink.Enabled    = (AttributeRepresentation = "SingleLineInputField");
	Items.MultilineInputFieldNumber.Enabled = (AttributeRepresentation = "MultilineInputField");
EndProcedure

&AtClient
Procedure Attachable_Opening(Item, StandardProcessing)
	
	If CommonClient.SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
		ModuleNationalLanguageSupportClient = CommonClient.CommonModule("NationalLanguageSupportClient");
		ModuleNationalLanguageSupportClient.OnOpen(ThisObject, Object, Item, StandardProcessing);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersPropertiesSets

&AtClient
Procedure PropertiesSetsOnActivateRow(Item)
	AttachIdleHandler("OnChangeCurrentSet", 0.1, True)
EndProcedure

&AtClient
Procedure PropertiesSetsBeforeRowChange(Item, Cancel)
	Cancel = True;
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersPropertiesSelection

&AtClient
Procedure PropertiesSelection(Item, RowSelected, Field, StandardProcessing)
	StandardProcessing = False;
	
	NextCommand(Undefined);
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersValues

&AtClient
Procedure ValuesOnChange(Item)
	
	If Item.CurrentData = Undefined Then
		Return;
	EndIf;
	
	If Object.ValueType.ContainsType(Type("CatalogRef.ObjectsPropertiesValues")) Then
		EventName = "Write_ObjectsPropertiesValues";
	Else
		EventName = "Write_ObjectPropertyValueHierarchy";
	EndIf;
	
	Notify(EventName,
		New Structure("Ref", Item.CurrentData.Ref),
		Item.CurrentData.Ref);
	
EndProcedure

&AtClient
Procedure ValuesBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	Cancel = True;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Copy", Copy);
	AdditionalParameters.Insert("Parent", Parent);
	AdditionalParameters.Insert("Group", Var_Group);
	
	FollowUpHandler = New CallbackDescription("ValuesBeforeAddRowCompletion", ThisObject);
	WriteObject("GoToValueList", FollowUpHandler, AdditionalParameters);
	
EndProcedure

&AtClient
Procedure ValuesBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	If Items.AdditionalValues.ReadOnly Then
		Return;
	EndIf;
	
	FollowUpHandler = New CallbackDescription("ValuesBeforeRowChangeCompletion", ThisObject);
	WriteObject("GoToValueList", FollowUpHandler);
	
EndProcedure

&AtClient
Procedure TitleOnChange(Item)
	If Not ValueIsFilled(Object.Ref) Then
		UpdateSuggestedIDValue();
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure NextCommand(Command)
	
#If WebClient Then
	If Not Items.AttributeCard.Visible Then
		Items.AttributeCard.Visible = True;
	EndIf;
#EndIf
	
	If AttributeAddMode = "AddCommonAttributeToSet" Then
		Result = New Structure;
		Result.Insert("CommonProperty", PassedFormParameters.AdditionalValuesOwner);
		If PassedFormParameters.Drag Then
			Result.Insert("Drag", True);
		EndIf;
		NotifyChoice(Result);
		Return;
	EndIf;
	
	BasicPage = Items.WIzardCardPages;
	PageIndex = BasicPage.ChildItems.IndexOf(BasicPage.CurrentPage);
	If PageIndex = 0
		And Items.Properties.CurrentData = Undefined Then
		WarningText = NStr("vi = 'Chưa chọn mục.';
							|ru = 'Элемент не выбран.';
							|en = 'Please select an item.'; fa = 'Please select an item.';
							|it = 'Elemento non selezionato.';
							|pl = 'Element nie został wybrany.';
							|tr = 'Öğe seçilmedi.'");
		ShowMessageBox(, WarningText);
		Return;
	EndIf;
	If PageIndex = 2 Then
		
		FillMultilingualRequisites();
		
		If Not CheckFilling() Then
			Return;
		EndIf;
		
		If AttributeAddMode = "CreateByCopying" Then
			Items.AttributeValuePages.CurrentPage = Items.AdditionalValues;
		EndIf;
		
		Write();
		If CancelOnWrite <> True Then
			Close();
		EndIf;
		Return;
	EndIf;
	CurrentPage = BasicPage.ChildItems.Get(PageIndex + 1);
	SetWizardSettings(CurrentPage);
	
	OnCurrentPageChange("GoForward", BasicPage, CurrentPage);
	
EndProcedure

&AtClient
Procedure BackCommand(Command)
	
	BasicPage = Items.WIzardCardPages;
	PageIndex = BasicPage.ChildItems.IndexOf(BasicPage.CurrentPage);
	If PageIndex = 1 Then
		AttributeAddMode = "";
	EndIf;
	CurrentPage = BasicPage.ChildItems.Get(PageIndex - 1);
	SetWizardSettings(CurrentPage);
	
	OnCurrentPageChange("Back", BasicPage, CurrentPage);
	
EndProcedure

&AtClient
Procedure CloseForm(Command)
	Close();
EndProcedure

&AtClient
Procedure EditValueFormat(Command)
	
	Designer = New FormatStringWizard(Object.FormatProperties);
	
	Designer.AvailableTypes = Object.ValueType;
	
	Designer.Show(
		New CallbackDescription("EditValueFormatCompletion", ThisObject));
	
EndProcedure

&AtClient
Procedure ValueListAdjustmentChange(Command)
	
	FollowUpHandler = New CallbackDescription("ValueListAdjustmentChangeCompletion", ThisObject);
	WriteObject("AttributeKindEdit", FollowUpHandler);
	
EndProcedure

&AtClient
Procedure SetsAdjustmentChange(Command)
	
	FollowUpHandler = New CallbackDescription("SetsAdjustmentChangeCompletion", ThisObject);
	WriteObject("AttributeKindEdit", FollowUpHandler);
	
EndProcedure

&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)
	
	LockedAttributes = ObjectAttributesLockClient.Attributes(ThisObject);
	
	If LockedAttributes.Count() > 0 Then
		
		FormParameters = New Structure;
		FormParameters.Insert("Ref", Object.Ref);
		FormParameters.Insert("IsAdditionalAttribute", Not Object.IsAdditionalInfo);
		FormParameters.Insert("PropertyKind1", Object.PropertyKind1);
		
		Notification = New CallbackDescription("AfterAttributesToUnlockChoice", ThisObject);
		OpenForm("ChartOfCharacteristicTypes.AdditionalAttributesAndInfo.Form.AttributeUnlocking",
			FormParameters, ThisObject,,,, Notification);
	Else
		ObjectAttributesLockClient.ShowAllVisibleAttributesUnlockedWarning();
	EndIf;
	
EndProcedure

&AtClient
Procedure DuplicateObjectsDetection(Command)
	ModuleDuplicateObjectsDetectionClient = CommonClient.CommonModule("DuplicateObjectsDetectionClient");
	DuplicateObjectsDetectionFormName = ModuleDuplicateObjectsDetectionClient.DuplicateObjectsDetectionDataProcessorFormName();
	OpenForm(DuplicateObjectsDetectionFormName);
EndProcedure

&AtClient
Procedure Change(Command)
	
	If Items.Properties.CurrentData <> Undefined Then
		// Open the property form.
		FormParameters = New Structure;
		FormParameters.Insert("Key", Items.Properties.CurrentData.Property);
		FormParameters.Insert("CurrentPropertiesSet", SelectedPropertiesSet);
		
		OpenForm("ChartOfCharacteristicTypes.AdditionalAttributesAndInfo.ObjectForm",
			FormParameters, Items.Properties,,,,, FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
	
EndProcedure

&AtClient
Procedure ShowUnusedAttributes(Command)
	NewValue = Not Items.UnusedAttributes.Check;
	ShowUnusedAttributes = NewValue;
	Items.UnusedAttributes.Check = NewValue;
	If NewValue Then
		Items.PropertiesSetsPages.CurrentPage = Items.SharedSetsPage;
	Else
		Items.PropertiesSetsPages.CurrentPage = Items.AllSetsPage;
	EndIf;
	
	UpdateCurrentSetPropertiesList();
	
EndProcedure

&AtClient
Procedure SetClearDeletionMark(Command)
	FollowUpHandler = New CallbackDescription("SetClearDeletionMarkContinued", ThisObject);
	WriteObject("DeletionMarkEdit", FollowUpHandler);
EndProcedure

&AtClient
Procedure FillIDForFormulas(Command)
	FillIDForFormulasAtServer();
EndProcedure

&AtClient
Procedure PropertyGray(Command)
	
	Object.PropertyColor = PredefinedValue("Enum.PropertiesColors.Gray");
	SetLabelColor(ThisObject, Object.PropertyColor);
	
EndProcedure

&AtClient
Procedure PropertyLightBlue(Command)
	
	Object.PropertyColor = PredefinedValue("Enum.PropertiesColors.LightBlue");
	SetLabelColor(ThisObject, Object.PropertyColor);
	
EndProcedure

&AtClient
Procedure PropertyYellow(Command)
	
	Object.PropertyColor = PredefinedValue("Enum.PropertiesColors.Yellow");
	SetLabelColor(ThisObject, Object.PropertyColor);
	
EndProcedure

&AtClient
Procedure PropertyGreen(Command)
	
	Object.PropertyColor = PredefinedValue("Enum.PropertiesColors.Green");
	SetLabelColor(ThisObject, Object.PropertyColor);
	
EndProcedure

&AtClient
Procedure PropertyBrown(Command)
	
	Object.PropertyColor = PredefinedValue("Enum.PropertiesColors.GreenLime");
	SetLabelColor(ThisObject, Object.PropertyColor);
	
EndProcedure

&AtClient
Procedure PropertyRed(Command)
	
	Object.PropertyColor = PredefinedValue("Enum.PropertiesColors.Red");
	SetLabelColor(ThisObject, Object.PropertyColor);
	
EndProcedure

&AtClient
Procedure PropertyOrange(Command)
	
	Object.PropertyColor = PredefinedValue("Enum.PropertiesColors.Orange");
	SetLabelColor(ThisObject, Object.PropertyColor);
	
EndProcedure

&AtClient
Procedure PropertyPink(Command)
	
	Object.PropertyColor = PredefinedValue("Enum.PropertiesColors.Pink");
	SetLabelColor(ThisObject, Object.PropertyColor);
	
EndProcedure

&AtClient
Procedure PropertyBlue(Command)
	
	Object.PropertyColor = PredefinedValue("Enum.PropertiesColors.B");
	SetLabelColor(ThisObject, Object.PropertyColor);
	
EndProcedure

&AtClient
Procedure PropertyPurple(Command)
	
	Object.PropertyColor = PredefinedValue("Enum.PropertiesColors.Violet");
	SetLabelColor(ThisObject, Object.PropertyColor);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure UpdateSuggestedIDValue()
	
	SuggestedID = "";
	If Not Items.IDForFormulas.ReadOnly Then
		
		Presentation = Object.Title;
		If Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
			ModuleNationalLanguageSupportServer = Common.CommonModule("NationalLanguageSupportServer");
			CurrentLanguageSuffix = ModuleNationalLanguageSupportServer.CurrentLanguageSuffix();
			If ValueIsFilled(CurrentLanguageSuffix) And ValueIsFilled(Object["Title" + CurrentLanguageSuffix]) Then
				Presentation = Object["Title" + CurrentLanguageSuffix];
			EndIf;
		EndIf;
		
		SuggestedID = ChartsOfCharacteristicTypes.AdditionalAttributesAndInfo.UUIDForFormulas(
			Presentation, Object.Ref);
		If SuggestedID <> Object.IDForFormulas Then
			Object.IDForFormulas = SuggestedID;
			Modified = True;
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillIDForFormulasAtServer()
	
	TitleForID = Object.Title;
	If Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
		ModuleNationalLanguageSupportServer = Common.CommonModule("NationalLanguageSupportServer");
		CurrentLanguageSuffix = ModuleNationalLanguageSupportServer.CurrentLanguageSuffix();
		If ValueIsFilled(CurrentLanguageSuffix) And ValueIsFilled(Object["Title" + CurrentLanguageSuffix]) Then
			TitleForID = Object["Title" + CurrentLanguageSuffix];
		EndIf;
	EndIf;
	
	Object.IDForFormulas = ChartsOfCharacteristicTypes.AdditionalAttributesAndInfo.UUIDForFormulas(
		TitleForID, Object.Ref);
EndProcedure

&AtServer
Procedure SetAdditionalAttributeDependencies()
	
	If AttributeDependencyConditions.Count() = 0 Then
		Return;
	EndIf;
	
	CurrentObject = FormAttributeToValue("Object");
	
	AdditionalAttributesDependencies = CurrentObject.AdditionalAttributesDependencies;
	
	For Each DependenceCondition In AttributeDependencyConditions Do
		RowFilter = New Structure;
		RowFilter.Insert("DependentProperty", DependenceCondition.Presentation);
		RowFilter.Insert("PropertiesSet", CurrentPropertiesSet);
		RowsArray = AdditionalAttributesDependencies.FindRows(RowFilter);
		For Each LineOfATabularSection In RowsArray Do
			AdditionalAttributesDependencies.Delete(LineOfATabularSection);
		EndDo;
		
		ValueFromStorage = GetFromTempStorage(DependenceCondition.Value);
		If ValueFromStorage = Undefined Then
			Continue;
		EndIf;
		For Each NewDependence In ValueFromStorage.Get() Do
			FillPropertyValues(CurrentObject.AdditionalAttributesDependencies.Add(), NewDependence);
		EndDo;
	EndDo;
	
	ValueToFormAttribute(CurrentObject, "Object");
	
	SetHyperlinkTitles();
	
EndProcedure

&AtServer
Procedure FillChoicePage()
	
	If PassedFormParameters.PropertyKind1 <> Undefined Then
		PropertyKind1 = PassedFormParameters.PropertyKind1;
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Sets.Ref AS Ref
	|FROM
	|	Catalog.AdditionalAttributesAndInfoSets AS Sets
	|WHERE
	|	Sets.Parent = VALUE(Catalog.AdditionalAttributesAndInfoSets.EmptyRef)";
	
	Sets = Query.Execute().Unload().UnloadColumn("Ref");
	
	AvailableSets = New Array;
	For Each Ref In Sets Do
		SetPropertiesTypes = PropertyManagerInternal.SetPropertiesTypes(Ref, False);
		
		If PropertyKind1 = Enums.PropertiesKinds.AdditionalInfo And SetPropertiesTypes.AdditionalInfo
			Or PropertyKind1 = Enums.PropertiesKinds.AdditionalAttributes And SetPropertiesTypes.AdditionalAttributes
			Or PropertyKind1 = Enums.PropertiesKinds.Labels And SetPropertiesTypes.Labels Then
			AvailableSets.Add(Ref);
		EndIf;
	EndDo;
	
	CurrentSetParent = Common.ObjectAttributeValue(
		PassedFormParameters.CurrentPropertiesSet, "Parent");
	SetsToExclude = New Array;
	SetsToExclude.Add(PassedFormParameters.CurrentPropertiesSet);
	If ValueIsFilled(CurrentSetParent) Then
		PredefinedSets = PropertyManagerCached.PredefinedPropertiesSets();
		SetProperties = PredefinedSets.Get(CurrentSetParent); // See Catalogs.AdditionalAttributesAndInfoSets.SetProperties
		If SetProperties = Undefined Then
			PredefinedDataName = Common.ObjectAttributeValue(CurrentSetParent, "PredefinedDataName");
		Else
			PredefinedDataName = SetProperties.Name;
		EndIf;
		ReplacedCharacterPosition = StrFind(PredefinedDataName, "_");
		FullObjectName = Left(PredefinedDataName, ReplacedCharacterPosition - 1)
			             + "."
			             + Mid(PredefinedDataName, ReplacedCharacterPosition + 1);
		Manager         = Common.ObjectManagerByFullName(FullObjectName);
		
		If StrStartsWith(FullObjectName, "Document") Then
			NewObject = Manager.CreateDocument();
		ElsIf StrStartsWith(FullObjectName, "BusinessProcess") Then
			NewObject = Manager.CreateBusinessProcess();
		ElsIf StrStartsWith(FullObjectName, "Task") Then
			NewObject = Manager.CreateTask();
		ElsIf StrStartsWith(FullObjectName, "ChartOfAccounts") Then
			NewObject = Manager.CreateAccount();
		ElsIf StrStartsWith(FullObjectName, "ChartOfCalculationTypes") Then
			NewObject = Manager.CreateCalculationType();
		ElsIf StrStartsWith(FullObjectName, "ExchangePlan") Then
			NewObject = Manager.CreateNode();
		Else
			NewObject = Manager.CreateItem();
		EndIf;
		ObjectSets = PropertyManagerInternal.GetObjectPropertySets(NewObject);
		
		FilterParameters = New Structure;
		FilterParameters.Insert("SharedSet", True);
		FoundRows = ObjectSets.FindRows(FilterParameters);
		For Each FoundRow In FoundRows Do
			If PassedFormParameters.CurrentPropertiesSet = FoundRow.Set Then
				Continue;
			EndIf;
			SetsToExclude.Add(FoundRow.Set);
		EndDo;
	EndIf;
	
	If PropertyKind1 = Enums.PropertiesKinds.AdditionalInfo Then
		Items.UnusedAttributes.Title = NStr("vi = 'Thông tin bổ sung không sử dụng';
											|ru = 'Неиспользуемые дополнительные сведения';
											|en = 'Unused additional information records'; fa = 'Unused additional information records';
											|it = 'Informazioni aggiuntive non in uso';
											|pl = 'Nieużywane informacje dodatkowe';
											|tr = 'Kullanılmayan ek bilgiler'");
	ElsIf PropertyKind1 = Enums.PropertiesKinds.Labels Then
		Items.UnusedAttributes.Title = NStr("vi = 'Nhãn đánh dấu không sử dụng';
											|ru = 'Неиспользуемые метки';
											|en = 'Unused labels'; fa = 'Unused labels';
											|it = 'Неиспользуемые метки';
											|pl = 'Unused labels';
											|tr = 'Kullanılmayan etiketler'");
	Else
		Items.UnusedAttributes.Title = NStr("vi = 'Chi tiết bổ sung không sử dụng';
											|ru = 'Неиспользуемые дополнительные реквизиты';
											|en = 'Unused additional attributes'; fa = 'Unused additional attributes';
											|it = 'Requisiti aggiuntivi non in uso';
											|pl = 'Nieużywane dodatkowe atrybuty';
											|tr = 'Kullanılmayan ek öznitelikler'");
	EndIf;
	
	CommonClientServer.SetDynamicListParameter(
		PropertiesSets, "Sets", AvailableSets, True);
	
	CommonClientServer.SetDynamicListParameter(
		PropertiesSets, "SetsToExclude", SetsToExclude, True);
	
	CommonClientServer.SetDynamicListParameter(
		PropertiesSets, "PropertyKind1", PropertyKind1, True);
	
	CommonClientServer.SetDynamicListParameter(
		PropertiesSets, "IsMainLanguage", Common.IsMainLanguage(), True);
	
	CommonClientServer.SetDynamicListParameter(
		PropertiesSets, "LanguageCode", CurrentLanguage().LanguageCode, True);
	
	CommonClientServer.SetDynamicListParameter(
		CommonPropertySets, "PropertyKind1", PropertyKind1, True);
	
	ListPresentation = "";
	If PropertyKind1 = PredefinedValue("Enum.PropertiesKinds.AdditionalInfo") Then
		ListPresentation = NStr("vi = 'Thông tin bổ sung không sử dụng';
								|ru = 'Неиспользуемые дополнительные сведения';
								|en = 'Unused additional information records'; fa = 'Unused additional information records';
								|it = 'Informazioni aggiuntive non in uso';
								|pl = 'Nieużywane informacje dodatkowe';
								|tr = 'Kullanılmayan ek bilgiler'");
	ElsIf PropertyKind1 = PredefinedValue("Enum.PropertiesKinds.AdditionalAttributes") Then
		ListPresentation = NStr("vi = 'Mục tin bổ sung không sử dụng';
								|ru = 'Неиспользуемые дополнительные реквизиты';
								|en = 'Unused additional attributes'; fa = 'Unused additional attributes';
								|it = 'Requisiti aggiuntivi non in uso';
								|pl = 'Nieużywane dodatkowe atrybuty';
								|tr = 'Kullanılmayan ek öznitelikler'");
	ElsIf PropertyKind1 = PredefinedValue("Enum.PropertiesKinds.Labels") Then
		ListPresentation = NStr("vi = 'Nhãn đánh dấu không sử dụng';
								|ru = 'Неиспользуемые метки';
								|en = 'Unused labels'; fa = 'Unused labels';
								|it = 'Неиспользуемые метки';
								|pl = 'Unused labels';
								|tr = 'Kullanılmayan etiketler'");
	EndIf;
	
	CommonClientServer.SetDynamicListParameter(
		CommonPropertySets, "ListPresentation", ListPresentation, True);
	
	SetConditionalListAppearance(AvailableSets);
	
EndProcedure

&AtServer
Procedure SetConditionalListAppearance(AvailableSetsList)
	
	ConditionalAppearanceItem = PropertiesSets.ConditionalAppearance.Items.Add();
	
	VisibilityItem = ConditionalAppearanceItem.Appearance.Items.Find("Visible");
	VisibilityItem.Value = False;
	VisibilityItem.Use = True;
	
	DataFilterItemsGroup = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	DataFilterItemsGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	DataFilterItemsGroup.Use = True;
	
	DataFilterItem = DataFilterItemsGroup.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue  = New DataCompositionField("Ref");
	DataFilterItem.ComparisonType   = DataCompositionComparisonType.NotInList;
	DataFilterItem.RightValue = AvailableSetsList;
	DataFilterItem.Use  = True;
	
	DataFilterItem = DataFilterItemsGroup.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue  = New DataCompositionField("Parent");
	DataFilterItem.ComparisonType   = DataCompositionComparisonType.NotInList;
	DataFilterItem.RightValue = AvailableSetsList;
	DataFilterItem.Use  = True;
	
EndProcedure

&AtServer
Procedure FillAdditionalAttributesValues(ValuesOwner)
	
	ValueTree = FormAttributeToValue("AdditionalAttributesValues");
	
	Query = New Query;
	Query.Text =
		"SELECT
		|	ObjectsPropertiesValues.Ref AS Ref,
		|	ObjectsPropertiesValues.Owner AS Owner,
		|	0 AS PictureCode,
		|	ObjectsPropertiesValues.Weight,
		|	PRESENTATION(ObjectsPropertiesValues.Ref) AS Description
		|FROM
		|	Catalog.ObjectsPropertiesValues AS ObjectsPropertiesValues
		|WHERE
		|	ObjectsPropertiesValues.DeletionMark = FALSE
		|	AND ObjectsPropertiesValues.Owner = &Owner
		|
		|UNION ALL
		|
		|SELECT
		|	ObjectPropertyValueHierarchy.Ref,
		|	ObjectPropertyValueHierarchy.Owner,
		|	0,
		|	ObjectPropertyValueHierarchy.Weight,
		|	PRESENTATION(ObjectPropertyValueHierarchy.Description) AS Description
		|FROM
		|	Catalog.ObjectPropertyValueHierarchy AS ObjectPropertyValueHierarchy
		|WHERE
		|	ObjectPropertyValueHierarchy.DeletionMark = FALSE
		|	AND ObjectPropertyValueHierarchy.Owner = &Owner
		|
		|ORDER BY
		|	Ref HIERARCHY";
	Query.SetParameter("Owner", ValuesOwner);
	Result = Query.Execute().Unload(QueryResultIteration.ByGroupsWithHierarchy);
	
	ValueTree = Result.Copy();
	ValueToFormAttribute(ValueTree, "AdditionalAttributesValues");
	
EndProcedure

&AtServer
Procedure FillPropertyCard()
	
	If ValueIsFilled(PassedFormParameters.CopyingValue) Then
		AttributeAddMode = "CreateByCopying";
	EndIf;
	
	CreateAttributeByCopying = (AttributeAddMode = "CreateByCopying");
	
	CurrentPropertiesSet = PassedFormParameters.CurrentPropertiesSet;
	
	If ValueIsFilled(Object.Ref) Then
		Items.PropertyKind1.Enabled = False;
		ShowSetAdjustment = PassedFormParameters.ShowSetAdjustment;
	Else
		Object.Available = True;
		Object.isVisible  = True;
		
		Object.AdditionalAttributesDependencies.Clear();
		If ValueIsFilled(CurrentPropertiesSet) Then
			Object.PropertiesSet = CurrentPropertiesSet;
		EndIf;
		
		If CreateAttributeByCopying Then
			Object.AdditionalValuesOwner = ChartsOfCharacteristicTypes.AdditionalAttributesAndInfo.EmptyRef();
		ElsIf ValueIsFilled(PassedFormParameters.AdditionalValuesOwner) Then
			Object.AdditionalValuesOwner = PassedFormParameters.AdditionalValuesOwner;
		EndIf;
		
		If PassedFormParameters.PropertyKind1 <> Undefined Then
			Object.PropertyKind1 = PassedFormParameters.PropertyKind1;
			If Object.PropertyKind1 = Enums.PropertiesKinds.AdditionalInfo Then
				Object.IsAdditionalInfo = True;
			EndIf;
		ElsIf Not ValueIsFilled(PassedFormParameters.CopyingValue) Then
			Items.PropertyKind1.Visible = True;
		EndIf;
	EndIf;
	
	If Object.Predefined And Not ValueIsFilled(Object.Title) Then
		Object.Title = Object.Description;
	EndIf;
	
	PropertyKind1 = Object.PropertyKind1;
	
	If CreateAttributeByCopying Then
		// For cases when the attribute is copied from its card using the Copy command.
		If Not ValueIsFilled(PassedFormParameters.AdditionalValuesOwner) Then
			PassedFormParameters.AdditionalValuesOwner = PassedFormParameters.CopyingValue;
		EndIf;
		
		OwnerProperties = Common.ObjectAttributesValues(
			PassedFormParameters.AdditionalValuesOwner, "ValueType, AdditionalValuesWithWeight, FormatProperties");
		
		Object.ValueType    = OwnerProperties.ValueType;
		Object.FormatProperties = OwnerProperties.FormatProperties;
		
		OwnerValuesWithWeight                                = OwnerProperties.AdditionalValuesWithWeight;
		Object.AdditionalValuesWithWeight                    = OwnerValuesWithWeight;
		Items.AdditionalAttributeValues.Header        = OwnerValuesWithWeight;
		Items.AdditionalAttributeValuesWeight.Visible = OwnerValuesWithWeight;
		Items.AttributeValuePages.CurrentPage     = Items.ValueTreePage;
		
		FillAdditionalAttributesValues(PassedFormParameters.AdditionalValuesOwner);
	EndIf;
	
	RefreshFormItemsContent();
	
	If Object.MultilineInputField > 0 Then
		AttributeRepresentation = "MultilineInputField";
		MultilineInputFieldNumber = Object.MultilineInputField;
	Else
		AttributeRepresentation = "SingleLineInputField";
	EndIf;
	
	Items.OutputAsHyperlink.Enabled    = (AttributeRepresentation = "SingleLineInputField");
	Items.MultilineInputFieldNumber.Enabled = (AttributeRepresentation = "MultilineInputField");
	
EndProcedure

&AtClient
Procedure FillMultilingualRequisites()
	
	If Not CommonClient.SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
		Return;
	EndIf;
	
	If IsBlankString(Object.TitleLanguage1) Then
		Object.TitleLanguage1 = Object.Title;
	EndIf;
	
	If IsBlankString(Object.TitleLanguage2) Then
		Object.TitleLanguage2 = Object.Title;
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterAttributesToUnlockChoice(AttributesToUnlock, Context) Export
	
	If TypeOf(AttributesToUnlock) <> Type("Array") Then
		Return;
	EndIf;
	
	ObjectAttributesLockClient.SetFormItemEnabled(ThisObject,
		AttributesToUnlock);
	Items.FillIDForFormulas.Enabled = Not Items.IDForFormulas.ReadOnly;
	
EndProcedure

&AtClient
Procedure AfterResponseOnQuestionWhenDescriptionIsAlreadyUsed(Response, WriteParameters) Export
	
	If Response <> "ContinueWrite" Then
		CurrentItem = Items.Title;
		If WriteParameters.Property("ContinuationHandler") Then
			RunCallback(
				New CallbackDescription(WriteParameters.ContinuationHandler.ProcedureName,
					ThisObject, WriteParameters.ContinuationHandler.Parameters),
				True);
		EndIf;
	Else
		WriteParameters.Insert("WhenDescriptionAlreadyInUse");
		Write(WriteParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterResponseToDescriptionChangeQuestion(Response, WriteParameters) Export
	
	If Response <> "ContinueWrite" Then
		Object.Title = CurrentTitle;
		If WriteParameters.Property("ContinuationHandler") Then
			RunCallback(
				New CallbackDescription(WriteParameters.ContinuationHandler.ProcedureName,
					ThisObject, WriteParameters.ContinuationHandler.Parameters),
				True);
		EndIf;
	Else
		WriteParameters.Insert("DescriptionChangeConfirmed");
		Write(WriteParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterResponseOnQuestionWhenNameIsAlreadyUsed(Response, WriteParameters) Export
	
	If Response <> "ContinueWrite" Then
		CurrentItem = Items.Title;
		If WriteParameters.Property("ContinuationHandler") Then
			RunCallback(
				New CallbackDescription(WriteParameters.ContinuationHandler.ProcedureName,
					ThisObject, WriteParameters.ContinuationHandler.Parameters),
				True);
		EndIf;
	Else
		WriteParameters.Insert("WhenNameAlreadyInUse");
		Write(WriteParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterResponseOnQuestionWhenIDForFormulasIsAlreadyUsed(Response, WriteParameters) Export
	
	If Response <> "ContinueWrite" Then
		If WriteParameters.Property("ContinuationHandler") Then
			RunCallback(
				New CallbackDescription(WriteParameters.ContinuationHandler.ProcedureName,
					ThisObject, WriteParameters.ContinuationHandler.Parameters),
				True);
		EndIf;
	Else
		WriteParameters.Insert("WhenIDForFormulasIsAlreadyUsed");
		Write(WriteParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterConfirmClearWeightCoefficients(Response, Context) Export
	
	If Response <> "ClearAndWrite" Then
		Object.AdditionalValuesWithWeight = Not Object.AdditionalValuesWithWeight;
		Return;
	EndIf;
	
	WriteParameters = New Structure;
	WriteParameters.Insert("ClearEnteredWeightCoefficients");
	
	FollowUpHandler = New CallbackDescription("AdditionalValuesWithWeightOnChangeCompletion", ThisObject);
	WriteObject("WeightUsageEdit", FollowUpHandler,, WriteParameters);
	
EndProcedure

&AtClient
Procedure AfterConfirmEnableWeightCoefficients(Response, Context) Export
	
	If Response <> "Write" Then
		Object.AdditionalValuesWithWeight = Not Object.AdditionalValuesWithWeight;
		Return;
	EndIf;
	
	FollowUpHandler = New CallbackDescription("AdditionalValuesWithWeightOnChangeCompletion", ThisObject);
	WriteObject("WeightUsageEdit", FollowUpHandler);
	
EndProcedure

&AtClient
Procedure AdditionalValuesWithWeightOnChangeCompletion(Cancel, Context) Export
	
	If Cancel Then
		Object.AdditionalValuesWithWeight = Not Object.AdditionalValuesWithWeight;
		Return;
	EndIf;
	
	If ValueIsFilled(Object.Ref) Then
		Notify(
			"ChangeValueIsCharacterizedByWeightCoefficient",
			Object.AdditionalValuesWithWeight,
			Object.Ref);
	EndIf;
	
EndProcedure

&AtClient
Procedure ValueListAdjustmentCommentClickCompletion(Cancel, Context) Export
	
	If Cancel Then
		Return;
	EndIf;
	
	Close();
	
	FormParameters = New Structure;
	FormParameters.Insert("ShowSetAdjustment", True);
	FormParameters.Insert("Key", Object.AdditionalValuesOwner);
	FormParameters.Insert("CurrentPropertiesSet", CurrentPropertiesSet);
	
	OpenForm("ChartOfCharacteristicTypes.AdditionalAttributesAndInfo.ObjectForm",
		FormParameters, FormOwner);
	
EndProcedure

&AtClient
Procedure SetsAdjustmentCommentClickContinued(Cancel, Context) Export
	
	If Cancel Then
		Return;
	EndIf;
	
	If SetsList.Count() > 1 Then
		ShowChooseFromList(
			New CallbackDescription("SetsAdjustmentCommentClickCompletion", ThisObject),
			SetsList, Items.SetsAdjustmentComment);
	Else
		SetsAdjustmentCommentClickCompletion(Undefined, SetsList[0].Value);
	EndIf;
	
EndProcedure

&AtClient
Procedure SetsAdjustmentCommentClickCompletion(SelectedElement, Selected_2Set) Export
	
	If SelectedElement <> Undefined Then
		Selected_2Set = SelectedElement.Value;
	EndIf;
	
	If Not ValueIsFilled(CurrentPropertiesSet) Then
		Return;
	EndIf;
	
	If Selected_2Set <> Undefined Then
		SelectionValue = New Structure;
		SelectionValue.Insert("Set", Selected_2Set);
		SelectionValue.Insert("Property", Object.Ref);
		If Not ValueIsFilled(Object.PropertyKind1)
			And Object.IsAdditionalInfo Then
			SelectionValue.Insert("PropertyKind1", PredefinedValue("Enum.PropertiesKinds.AdditionalInfo"));
		ElsIf Not ValueIsFilled(Object.PropertyKind1)
			And Not Object.IsAdditionalInfo Then
			SelectionValue.Insert("PropertyKind1", PredefinedValue("Enum.PropertiesKinds.AdditionalAttributes"));
		Else
			SelectionValue.Insert("PropertyKind1", Object.PropertyKind1);
		EndIf;
		
		NotifyChoice(SelectionValue);
	EndIf;
	
EndProcedure

&AtClient
Procedure ValuesBeforeAddRowCompletion(Cancel, ProcessingParameters) Export
	
	If Cancel Then
		Return;
	EndIf;
	
	If AttributeAddMode = "CreateByCopying" Then
		Items.AttributeValuePages.CurrentPage = Items.AdditionalValues;
	EndIf;
	
	If Object.ValueType.ContainsType(Type("CatalogRef.ObjectsPropertiesValues")) Then
		ValueTableName = "Catalog.ObjectsPropertiesValues";
	Else
		ValueTableName = "Catalog.ObjectPropertyValueHierarchy";
	EndIf;
	
	FillingValues = New Structure;
	FillingValues.Insert("Parent", ProcessingParameters.Parent);
	FillingValues.Insert("Owner", Object.Ref);
	
	FormParameters = New Structure;
	FormParameters.Insert("HideOwner", True);
	FormParameters.Insert("FillingValues", FillingValues);
	
	If ProcessingParameters.Group Then
		FormParameters.Insert("IsFolder", True);
		
		OpenForm(ValueTableName + ".FolderForm", FormParameters, Items.Values);
	Else
		FormParameters.Insert("ShowWeight", Object.AdditionalValuesWithWeight);
		
		If ProcessingParameters.Copy Then
			FormParameters.Insert("CopyingValue", Items.Values.CurrentRow);
		EndIf;
		
		OpenForm(ValueTableName + ".ObjectForm", FormParameters, Items.Values);
	EndIf;
	
EndProcedure

&AtClient
Procedure ValuesBeforeRowChangeCompletion(Cancel, Context) Export
	
	If Cancel Then
		Return;
	EndIf;
	
	If Object.ValueType.ContainsType(Type("CatalogRef.ObjectsPropertiesValues")) Then
		ValueTableName = "Catalog.ObjectsPropertiesValues";
	Else
		ValueTableName = "Catalog.ObjectPropertyValueHierarchy";
	EndIf;
	
	If Items.Values.CurrentRow <> Undefined Then
		// Opening a value form or a value set.
		FormParameters = New Structure;
		FormParameters.Insert("HideOwner", True);
		FormParameters.Insert("ShowWeight", Object.AdditionalValuesWithWeight);
		FormParameters.Insert("Key", Items.Values.CurrentRow);
		
		OpenForm(ValueTableName + ".ObjectForm", FormParameters, Items.Values);
	EndIf;
	
EndProcedure

&AtClient
Procedure ValueListAdjustmentChangeCompletion(Cancel, Context) Export
	
	If Cancel Then
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("CurrentPropertiesSet", CurrentPropertiesSet);
	FormParameters.Insert("Property", Object.Ref);
	FormParameters.Insert("AdditionalValuesOwner", Object.AdditionalValuesOwner);
	FormParameters.Insert("IsAdditionalInfo", Object.IsAdditionalInfo);
	FormParameters.Insert("PropertyKind1", Object.PropertyKind1);
	
	OpenForm("ChartOfCharacteristicTypes.AdditionalAttributesAndInfo.Form.EditPropertySettings",
		FormParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure SetsAdjustmentChangeCompletion(Cancel, Context) Export
	
	If Cancel Then
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("CurrentPropertiesSet", CurrentPropertiesSet);
	FormParameters.Insert("Property", Object.Ref);
	FormParameters.Insert("AdditionalValuesOwner", Object.AdditionalValuesOwner);
	FormParameters.Insert("IsAdditionalInfo", Object.IsAdditionalInfo);
	FormParameters.Insert("PropertyKind1", Object.PropertyKind1);
	
	OpenForm("ChartOfCharacteristicTypes.AdditionalAttributesAndInfo.Form.EditPropertySettings",
		FormParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure WriteObject(QuestionTextVariant, FollowUpHandler, AdditionalParameters = Undefined, WriteParameters = Undefined)
	
	If WriteParameters = Undefined Then
		WriteParameters = New Structure;
	EndIf;
	
	If QuestionTextVariant = "DeletionMarkEdit" Then
		If Modified Then
			If Object.DeletionMark Then
				QueryText = NStr("vi = 'Để bỏ dấu xóa, hãy ghi lại những thay đổi đã thực hiện. Ghi lại dữ liệu?';
								|ru = 'Для снятия пометки удаления запишите внесенные изменения. Записать данные?';
								|en = 'Save the changes before clearing the deletion mark. Do you want to save the changes?'; fa = 'Save the changes before clearing the deletion mark. Do you want to save the changes?';
								|it = 'Per la rimozione del contrassegno di eliminazione salvare le modifiche apportate. Salvare i dati?';
								|pl = 'Aby usunąć zaznaczenie do usunięcia zapisz wprowadzone zmiany. Zapisać dane?';
								|tr = 'Silinme işaretinin kaldırılması için girilen değişiklikleri yazın. Veriler yazılsın mı?'");
			Else
				QueryText = NStr("vi = 'Để đặt dấu xóa, hãy ghi lại những thay đổi đã thực hiện. Ghi lại dữ liệu?';
								|ru = 'Для установки пометки удаления запишите внесенные изменения. Записать данные?';
								|en = 'Save the changes before marking for deletion. Do you want to save the changes?'; fa = 'Save the changes before marking for deletion. Do you want to save the changes?';
								|it = 'Per impostare il contrassegno per l''eliminazione registrare le modifiche apportate. Registrare dati?';
								|pl = 'Aby ustawić zaznaczenie do usunięcia zapisz wykonane zmiany. Zapisać dane?';
								|tr = 'Silinme işaretinin ayarlanması için girilen değişiklikleri yazın. Veriler yazılsın mı?'");
			EndIf;
		Else
			QueryText = NStr("vi = 'Đặt dấu xóa ""%1""?';
							|ru = 'Пометить ""%1"" на удаление?';
							|en = 'Do you want to mark ""%1"" for deletion?'; fa = 'Do you want to mark ""%1"" for deletion?';
							|it = 'Contrassegnare ""%1"" per cancellazione?';
							|pl = 'Zaznaczyć ""%1"" do usunięcia?';
							|tr = '""%1"" silinmek üzere işaretlensin mi?'");
			QueryText = StringFunctionsClientServer.SubstituteParametersToString(QueryText, Object.Description);
		EndIf;
		
		ShowQueryBox(
			New CallbackDescription(
				FollowUpHandler.ProcedureName, FollowUpHandler.Module, WriteParameters),
			QueryText, QuestionDialogMode.YesNo, , DialogReturnCode.Yes);
		Return;
	EndIf;
	
	If ValueIsFilled(Object.Ref) And Not Modified Then
		RunCallback(New CallbackDescription(
			FollowUpHandler.ProcedureName, FollowUpHandler.Module, AdditionalParameters), False);
		Return;
	EndIf;
	
	ContinuationHandler = New Structure;
	ContinuationHandler.Insert("ProcedureName", FollowUpHandler.ProcedureName);
	ContinuationHandler.Insert("Parameters", AdditionalParameters);
	WriteParameters.Insert("ContinuationHandler", ContinuationHandler);
	
	If ValueIsFilled(Object.Ref) Then
		ProcessingEndOfRecording = New CallbackDescription("WriteObjectContinued", ThisObject, WriteParameters);
		AttachIdleHandler("Attachable_EndOfObjectRecording", 0.1, True);
		Return;
	EndIf;
	
	If QuestionTextVariant = "GoToValueList" Then
		QueryText = NStr("vi = 'Trước khi chuyển đến danh sách các giá trị, dữ liệu sẽ được ghi lại.';
						|ru = 'Перед переходом к списку значений данные будут записаны.';
						|en = 'Do you want to save the data and open the list of values?'; fa = 'Do you want to save the data and open the list of values?';
						|it = 'Prima di passare all''elenco di valori i dati saranno salvati.';
						|pl = 'Przed przejściem do listy wartości dane zostaną zapisane.';
						|tr = 'Değerler listesine geçmeden önce veriler yazılacaktır.'");
	Else
		QueryText = NStr("vi = 'Dữ liệu sẽ được ghi lại.';
						|ru = 'Данные будут записаны.';
						|en = 'Do you want to save the data?'; fa = 'Do you want to save the data?';
						|it = 'I dati verranno registrati.';
						|pl = 'Dane zostaną zapisane.';
						|tr = 'Veriler yazılacaktır.'")
	EndIf;
	
	Buttons = New ValueList;
	Buttons.Add("Write", NStr("vi = 'Ghi lại';
								|ru = 'Записать';
								|en = 'Save'; fa = 'ذخیره';
								|it = 'Salvare';
								|pl = 'Save';
								|tr = 'Kaydet'"));
	Buttons.Add("Cancel", NStr("vi = 'Hủy bỏ';
								|ru = 'Отмена';
								|en = 'Cancel'; fa = 'انصراف';
								|it = 'Annulla';
								|pl = 'Cancel';
								|tr = 'İptal'"));
	
	ShowQueryBox(
		New CallbackDescription(
			"WriteObjectContinued", ThisObject, WriteParameters),
		QueryText, Buttons, , "Write");
	
EndProcedure

&AtClient
Procedure Attachable_EndOfObjectRecording()
	
	RunCallback(ProcessingEndOfRecording, "Write");
	
EndProcedure

&AtClient
Procedure SetClearDeletionMarkContinued(Response, WriteParameters) Export
	
	If Response = DialogReturnCode.Yes Then
		Object.DeletionMark = Not Object.DeletionMark;
	EndIf;
	WriteObjectContinued(Response, WriteParameters);
	
EndProcedure


&AtClient
Procedure WriteObjectContinued(Response, WriteParameters) Export
	
	If Response = "Write"
		Or Response = DialogReturnCode.Yes Then
		Write(WriteParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterWriteError()
	
	If ContinuationHandlerOnWriteError <> Undefined Then
		RunCallback(
			New CallbackDescription(ContinuationHandlerOnWriteError.ProcedureName,
				ThisObject, ContinuationHandlerOnWriteError.Parameters),
			True);
	EndIf;
	
EndProcedure

&AtClient
Procedure EditValueFormatCompletion(Text, Context) Export
	
	If Text <> Undefined Then
		Object.FormatProperties = Text;
		SetFormatButtonTitle(ThisObject);
		
		WarningText = NStr("vi = 'Tùy chỉnh tiếp theo định dạng tự động không được áp dụng trong tất cả các chỗ:';
							|ru = 'Следующие настройки формата автоматически не применяются в большинстве мест:';
							|en = 'The following format settings are not applied automatically in most cases:'; fa = 'The following format settings are not applied automatically in most cases:';
							|it = 'Le seguenti impostazioni di formato non si applicano automaticamente nella maggior parte delle posizioni:';
							|pl = 'Następujące ustawienia formatu nie są stosowane automatycznie w większości miejsc:';
							|tr = 'Aşağıdaki biçim ayarları çoğu yerde otomatik olarak uygulanmaz:'");
		Array = StrSplit(Text, ";", False);
		
		For Each Substring In Array Do
			If StrFind(Substring, "ДП=") > 0 Or StrFind(Substring, "DE=") > 0 Then // @Non-NLS
				WarningText = WarningText + Chars.LF
					+ " - " + NStr("vi = 'trình bày ngày rỗng';
									|ru = 'представление пустой даты';
									|en = 'Blank date presentation'; fa = 'Blank date presentation';
									|it = 'presentazione di una data vuota';
									|pl = 'prezentacja pustej daty';
									|tr = 'boş tarih görüntüleme'");
				Continue;
			EndIf;
			If StrFind(Substring, "ЧН=") > 0 Or StrFind(Substring, "NZ=") > 0 Then // @Non-NLS
				WarningText = WarningText + Chars.LF
					+ " - " + NStr("vi = 'trình bày số rỗng';
									|ru = 'представление пустого числа';
									|en = 'Blank number presentation'; fa = 'Blank number presentation';
									|it = 'presentazione di un numero vuoto';
									|pl = 'prezentacja pustej liczby';
									|tr = 'boş sayı görüntüleme'");
				Continue;
			EndIf;
			If StrFind(Substring, "ДФ=") > 0 Or StrFind(Substring, "DF=") > 0 Then // @Non-NLS
				If StrFind(Substring, "ддд") > 0 Or StrFind(Substring, "ddd") > 0 Then // @Non-NLS
					WarningText = WarningText + Chars.LF
						+ " - " + NStr("vi = 'tên gọi ngắn gọn ngày trong tuần';
										|ru = 'кратное название дня недели';
										|en = 'Short weekday name'; fa = 'Short weekday name';
										|it = 'nome breve del giorno della settimana';
										|pl = 'krotna nazwa dnia tygodnia';
										|tr = 'hafta gününün kısa adı'");
				EndIf;
				If StrFind(Substring, "дддд") > 0 Or StrFind(Substring, "dddd") > 0 Then // @Non-NLS
					WarningText = WarningText + Chars.LF
						+ " - " + NStr("vi = 'tên đầy đủ đối với tuần';
										|ru = 'полное название дня недели';
										|en = 'Full weekday name'; fa = 'Full weekday name';
										|it = 'nome completo del giorno della settimana';
										|pl = 'pełna nazwa dni tygodnia';
										|tr = 'hafta gününün tam adı'");
				EndIf;
				If StrFind(Substring, "МММ") > 0 Or StrFind(Substring, "MMM") > 0 Then // @Non-NLS
					WarningText = WarningText + Chars.LF
						+ " - " + NStr("vi = 'tên gọi ngắn gọn tháng';
										|ru = 'кратное название месяца';
										|en = 'Short month name'; fa = 'Short month name';
										|it = 'nome breve del mese';
										|pl = 'krotna nazwa miesiąca';
										|tr = 'ayın kısa adı'");
				EndIf;
				If StrFind(Substring, "ММММ") > 0 Or StrFind(Substring, "MMMM") > 0 Then // @Non-NLS
					WarningText = WarningText + Chars.LF
						+ " - " + NStr("vi = 'tên đầy đủ đối với tháng';
										|ru = 'полное название месяца';
										|en = 'Full month name'; fa = 'Full month name';
										|it = 'nome completo del mese';
										|pl = 'pełna nazwa miesiąca';
										|tr = 'ayın tam adı'");
				EndIf;
			EndIf;
			If StrFind(Substring, "ДЛФ=") > 0 Or StrFind(Substring, "DLF=") > 0 Then // @Non-NLS
				If StrFind(Substring, "ДД") > 0 Or StrFind(Substring, "DD") > 0 Then // @Non-NLS
					WarningText = WarningText + Chars.LF
						+ " - " + NStr("vi = 'ngày (tháng viết bằng chữ)';
										|ru = 'длинная дата (месяц прописью)';
										|en = 'Long date (month in words)'; fa = 'Long date (month in words)';
										|it = 'data lunga (mese in parole)';
										|pl = 'długa data (miesiąc słownie)';
										|tr = 'uzun tarih (ay yazı ile)'");
				EndIf;
			EndIf;
		EndDo;
		
		If StrLineCount(WarningText) > 1 Then
			ShowMessageBox(, WarningText);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure SetWizardSettings(CurrentPage = Undefined)
	
	If CurrentPage = Undefined Then
		CurrentPage = Items.WIzardCardPages.CurrentPage;
	EndIf;
	
	If CurrentPage = Items.SelectAttribute Then
		
		If PassedFormParameters.PropertyKind1 =
			PredefinedValue("Enum.PropertiesKinds.AdditionalInfo") Then
			Title = NStr("vi = 'Thêm mục tin bổ sung';
						|ru = 'Добавление дополнительного сведения';
						|en = 'Add additional information records'; fa = 'Add additional information records';
						|it = 'Aggiunta di un informazione aggiuntiva';
						|pl = 'Dodawanie informacji dodatkowej';
						|tr = 'Ek bilgi ilavesi'");
			ListHeaderTemplate =
				NStr("vi = 'Hãy chọn thông tin bổ sung để đưa vào sử dụng trong tập hợp ""%1""';
					|ru = 'Выберите дополнительное сведение для включения в набор ""%1""';
					|en = 'Select an additional information record to include in the ""%1"" set'; fa = 'Select an additional information record to include in the ""%1"" set';
					|it = 'Выберите дополнительное сведение для включения в набор ""%1""';
					|pl = 'Select an additional information record to include in the ""%1"" set';
					|tr = '""%1"" kümesine dahil edilecek ek bilgileri seçin'");
			RadioButtonHeaderTemplate =
				NStr("vi = 'Hãy chọn phương án thêm thông tin bổ sung ""%1"" vào tập hợp ""%2""';
					|ru = 'Выберите вариант добавления дополнительного сведения ""%1"" в набор ""%2""';
					|en = 'Select an option to add the ""%1"" additional information record to the ""%2"" set'; fa = 'Select an option to add the ""%1"" additional information record to the ""%2"" set';
					|it = 'Выберите вариант добавления дополнительного сведения ""%1"" в набор ""%2""';
					|pl = 'Select an option to add the ""%1"" additional information record to the ""%2"" set';
					|tr = '""%2"" kümesine ""%1"" ek bilgisi ekleme seçeneğini seçin'");
		ElsIf PassedFormParameters.PropertyKind1 =
			PredefinedValue("Enum.PropertiesKinds.Labels") Then
			Title = NStr("vi = 'Thêm nhãn đánh dấu';
						|ru = 'Добавление метки';
						|en = 'Add label'; fa = 'Add label';
						|it = 'Добавление метки';
						|pl = 'Add label';
						|tr = 'Etiket ekleme'");
			ListHeaderTemplate =
				NStr("vi = 'Hãy chọn nhãn đánh dấu để đưa vào sử dụng trong tập hợp ""%1""';
					|ru = 'Выберите метку для включения в набор ""%1""';
					|en = 'Select a label to include in the ""%1"" set'; fa = 'Select a label to include in the ""%1"" set';
					|it = 'Выберите метку для включения в набор ""%1""';
					|pl = 'Select a label to include in the ""%1"" set';
					|tr = '""%1"" kümesine dahil edilecek etiketi seçin'");
			RadioButtonHeaderTemplate =
				NStr("vi = 'Hãy chọn phương án thêm nhãn đánh dấu ""%1"" vào tập hợp ""%2""';
					|ru = 'Выберите вариант добавления метки ""%1"" в набор ""%2""';
					|en = 'Select an option to add the ""%1"" label to the ""%2"" set'; fa = 'Select an option to add the ""%1"" label to the ""%2"" set';
					|it = 'Выберите вариант добавления метки ""%1"" в набор ""%2""';
					|pl = 'Select an option to add the ""%1"" label to the ""%2"" set';
					|tr = '""%2"" kümesine ""%1"" etiketini ekleme seçeneğini seçin'");
		Else
			Title = NStr("vi = 'Thêm mục tin bổ sung';
						|ru = 'Добавление дополнительного реквизита';
						|en = 'Add additional attribute'; fa = 'Add additional attribute';
						|it = 'Aggiunta di un requisito aggiuntivo';
						|pl = 'Dodawanie atrybutu dodatkowego';
						|tr = 'Ek öznitelik ilavesi'");
			ListHeaderTemplate =
				NStr("vi = 'Hãy chọn mục tin bổ sung để đưa vào sử dụng trong tập hợp ""%1""';
					|ru = 'Выберите дополнительный реквизит для включения в набор ""%1""';
					|en = 'Select an additional attribute to include in the ""%1"" set'; fa = 'Select an additional attribute to include in the ""%1"" set';
					|it = 'Выберите дополнительный реквизит для включения в набор ""%1""';
					|pl = 'Select an additional attribute to include in the ""%1"" set';
					|tr = '""%1"" kümesine dahil edilecek ek özniteliği seçin'");
			RadioButtonHeaderTemplate =
				NStr("vi = 'Hãy chọn phương án thêm mục tin bổ sung ""%1"" vào tập hợp ""%2""';
					|ru = 'Выберите вариант добавления дополнительного реквизита ""%1"" в набор ""%2""';
					|en = 'Select an option to add the ""%1"" additional attribute to the ""%2"" set'; fa = 'Select an option to add the ""%1"" additional attribute to the ""%2"" set';
					|it = 'Выберите вариант добавления дополнительного реквизита ""%1"" в набор ""%2""';
					|pl = 'Select an option to add the ""%1"" additional attribute to the ""%2"" set';
					|tr = '""%2"" kümesine ""%1"" ek özniteliğini ekleme seçeneğini seçin'");
		EndIf;
		
		Items.CommandBarLeft.Enabled = False;
		Items.NextCommand.Title = NStr("vi = 'Tiếp theo >';
										|ru = 'Далее >';
										|en = 'Next >'; fa = 'بعدی >';
										|it = 'Avanti >';
										|pl = 'Dalej >';
										|tr = 'İleri >'");
		
		
		Items.TitleDecoration.Title = StringFunctionsClientServer.SubstituteParametersToString(
			ListHeaderTemplate,
			String(PassedFormParameters.CurrentPropertiesSet));
		
	ElsIf CurrentPage = Items.ActionChoice Then
		
		If PassedFormParameters.CopyWithQuestion Then
			Items.CommandBarLeft.Enabled = False;
			AdditionalValuesOwner = PassedFormParameters.AdditionalValuesOwner;
		Else
			Items.CommandBarLeft.Enabled = True;
			SelectedElement = Items.Properties.CurrentData;
			If SelectedElement = Undefined Then
				AdditionalValuesOwner = PassedFormParameters.AdditionalValuesOwner;
			Else
				AdditionalValuesOwner = Items.Properties.CurrentData.Property;
			EndIf;
		EndIf;
		Items.NextCommand.Title = NStr("vi = 'Tiếp theo >';
										|ru = 'Далее >';
										|en = 'Next >'; fa = 'بعدی >';
										|it = 'Avanti >';
										|pl = 'Dalej >';
										|tr = 'İleri >'");
		
		Items.AttributeAddMode.Title = StringFunctionsClientServer.SubstituteParametersToString(
			RadioButtonHeaderTemplate,
			String(AdditionalValuesOwner),
			String(PassedFormParameters.CurrentPropertiesSet));
		
		If PassedFormParameters.PropertyKind1 =
			PredefinedValue("Enum.PropertiesKinds.AdditionalInfo") Then
			Title = NStr("vi = 'Thêm mục tin bổ sung';
						|ru = 'Добавление дополнительного сведения';
						|en = 'Add additional information records'; fa = 'Add additional information records';
						|it = 'Aggiunta di un informazione aggiuntiva';
						|pl = 'Dodawanie informacji dodatkowej';
						|tr = 'Ek bilgi ilavesi'");
		ElsIf PassedFormParameters.PropertyKind1 =
			PredefinedValue("Enum.PropertiesKinds.Labels") Then
			Title = NStr("vi = 'Thêm nhãn đánh dấu';
						|ru = 'Добавление метки';
						|en = 'Add label'; fa = 'Add label';
						|it = 'Добавление метки';
						|pl = 'Add label';
						|tr = 'Etiket ekleme'");
		Else
			Title = NStr("vi = 'Thêm mục tin bổ sung';
						|ru = 'Добавление дополнительного реквизита';
						|en = 'Add additional attribute'; fa = 'Add additional attribute';
						|it = 'Aggiunta di un requisito aggiuntivo';
						|pl = 'Dodawanie atrybutu dodatkowego';
						|tr = 'Ek öznitelik ilavesi'");
		EndIf;
		
	Else
		Items.NextCommand.Title = NStr("vi = 'Đồng ý';
										|ru = 'Готово';
										|en = 'Finish'; fa = 'پایان';
										|it = 'Fine';
										|pl = 'Finish';
										|tr = 'Bitiş'");
		Items.CommandBarLeft.Enabled = True;
	EndIf;
	
EndProcedure

&AtServer
Procedure RefreshFormItemsContent(WarningText = "")
	
	If WizardMode Then
		CommandBarLocation = FormCommandBarLabelLocation.None;
		Items.NextCommand.DefaultButton    = True;
	Else
		Items.WizardCommandBar.Visible = False;
		Items.WIzardCardPages.CurrentPage = Items.AttributeCard;
	EndIf;
	
	SetFormHeader();
	
	If Not Object.ValueType.ContainsType(Type("Number"))
	   And Not Object.ValueType.ContainsType(Type("Date"))
	   And Not Object.ValueType.ContainsType(Type("Boolean")) Then
		
		Object.FormatProperties = "";
	EndIf;
	
	SetFormatButtonTitle(ThisObject);
	
	If Object.IsAdditionalInfo
	 Or Not (    Object.ValueType.ContainsType(Type("Number" ))
	         Or Object.ValueType.ContainsType(Type("Date"  ))
	         Or Object.ValueType.ContainsType(Type("Boolean")) )Then
		Items.EditValueFormat.Visible = False;
	Else
		Items.EditValueFormat.Visible = True;
	EndIf;
	
	If Object.IsAdditionalInfo
		And Object.ValueType.ContainsType(Type("String"))
		And Object.ValueType.StringQualifiers.Length = 0 Then
		Items.ValueTypeNoteGroup.Visible = True;
	Else
		Items.ValueTypeNoteGroup.Visible = False;
	EndIf;
	
	If Not Object.IsAdditionalInfo Then
		Items.MultilineGroup.Visible = True;
		SwitchAttributeDisplaySettings(Object.ValueType);
	Else
		Items.MultilineGroup.Visible = False;
	EndIf;
	
	If Object.PropertyKind1 = Enums.PropertiesKinds.Labels Then
		Object.ValueType = New TypeDescription("Boolean");
		Items.ValueTypeGroup.Visible = False;
		Items.GroupPropertiesColors.Visible = True;
		Items.OutputAsHyperlink.Visible = False;
		Items.ItemVisibilityGroup.Visible = False;
		Items.ItemAvailabilityGroup.Visible = False;
		Items.PropertyGray.Check = True;
		Items.Title.TypeRestriction = New TypeDescription("String",, New StringQualifiers(15));
		If Not ValueIsFilled(Object.PropertyColor) Then
			Object.PropertyColor = Enums.PropertiesColors.Gray;
		EndIf;
		SetLabelColor(ThisObject, Object.PropertyColor);
	EndIf;
	
	If ValueIsFilled(Object.Ref) Then
		OldValueType = Common.ObjectAttributeValue(Object.Ref, "ValueType");
	Else
		OldValueType = New TypeDescription;
	EndIf;
	
	If Object.IsAdditionalInfo Then
		Object.RequiredToFill = False;
		Items.PropertiesAndDependenciesGroup.Visible = False;
	Else
		AttributeBoolean = (Object.ValueType = New TypeDescription("Boolean"));
		Items.RequiredToFill.Visible    = Not AttributeBoolean;
		Items.ChooseItemRequiredOption.Visible = Not AttributeBoolean;
		Items.PropertiesAndDependenciesGroup.Visible = True;
		
		Items.ChooseItemRequiredOption.Enabled  = Object.RequiredToFill;
		Items.ChooseAvailabilityOption.Enabled = True;
		Items.ChooseVisibilityOption.Enabled   = True;
		
		SetHyperlinkTitles();
	EndIf;
	
	If ValueIsFilled(Object.AdditionalValuesOwner) Then
		
		OwnerProperties = Common.ObjectAttributesValues(
			Object.AdditionalValuesOwner, "ValueType, AdditionalValuesWithWeight");
		
		If OwnerProperties.ValueType.ContainsType(Type("CatalogRef.ObjectPropertyValueHierarchy")) Then
			Object.ValueType = New TypeDescription(
				Object.ValueType,
				"CatalogRef.ObjectPropertyValueHierarchy",
				"CatalogRef.ObjectsPropertiesValues");
		Else
			Object.ValueType = New TypeDescription(
				Object.ValueType,
				"CatalogRef.ObjectsPropertiesValues",
				"CatalogRef.ObjectPropertyValueHierarchy");
		EndIf;
		
		ValuesOwner = Object.AdditionalValuesOwner;
		ValuesWithWeight   = OwnerProperties.AdditionalValuesWithWeight;
	Else
		// Checking possibility to delete an additional value type.
		If PropertyManagerInternal.ValueTypeContainsPropertyValues(OldValueType) Then
			Query = New Query;
			Query.SetParameter("Owner", Object.Ref);
			
			If OldValueType.ContainsType(Type("CatalogRef.ObjectPropertyValueHierarchy")) Then
				Query.Text =
				"SELECT TOP 1
				|	TRUE AS TrueValue
				|FROM
				|	Catalog.ObjectPropertyValueHierarchy AS ObjectPropertyValueHierarchy
				|WHERE
				|	ObjectPropertyValueHierarchy.Owner = &Owner";
			Else
				Query.Text =
				"SELECT TOP 1
				|	TRUE AS TrueValue
				|FROM
				|	Catalog.ObjectsPropertiesValues AS ObjectsPropertiesValues
				|WHERE
				|	ObjectsPropertiesValues.Owner = &Owner";
			EndIf;
			
			If Not Query.Execute().IsEmpty() Then
				
				If OldValueType.ContainsType(Type("CatalogRef.ObjectPropertyValueHierarchy"))
				   And Not Object.ValueType.ContainsType(Type("CatalogRef.ObjectPropertyValueHierarchy")) Then
					
					WarningText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Không được phép xóa loại ""%1"", 
						           | vì các giá trị bổ sung đã được nhập.
						           |Trước tiên, phải xóa các giá trị bổ sung đã nhập.
						           |
						           |Việc xóa đã bị hủy.';
						           |ru = 'Недопустимо удалять тип ""%1"",
						           |так как дополнительные значения уже введены.
						           |Сначала нужно удалить введенные дополнительные значения.
						           |
						           |Удаление отменено.';
						           |en = 'Cannot delete the ""%1"" type
						           |as additional values are already entered.
						           |Please delete the additional values first.
						           |
						           |The deletion is canceled.'; fa = 'Cannot delete the ""%1"" type
						           |as additional values are already entered.
						           |Please delete the additional values first.
						           |
						           |The deletion is canceled.';
						           |it = 'Non è consentito eliminare il tipo ""%1"",
						           | in quanto i valori aggiuntivi sono già stati inseriti.
						           |Prima devono essere eliminati i valori aggiuntivi.
						           |
						           |Eliminazione annullata.';
						           |pl = 'Usuwanie typu ""%1"" jest niedozwolone,
						           |ponieważ dodatkowe wartości zostały już wprowadzone.
						           |Najpierw należy usunąć wprowadzone wartości dodatkowe.
						           |
						           |Usunięcie jest anulowane.';
						           |tr = '""%1"" türü silinemez,
						           |çünkü ek değerler artık girildi.
						           |Önce ek değerlerin silinmesi gerekiyor.
						           |
						           |Silinme iptal edildi.'"),
						String(Type("CatalogRef.ObjectPropertyValueHierarchy")) );
					
					Object.ValueType = New TypeDescription(
						Object.ValueType,
						"CatalogRef.ObjectPropertyValueHierarchy",
						"CatalogRef.ObjectsPropertiesValues");
				
				ElsIf OldValueType.ContainsType(Type("CatalogRef.ObjectsPropertiesValues"))
				        And Not Object.ValueType.ContainsType(Type("CatalogRef.ObjectsPropertiesValues")) Then
					
					WarningText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Không được phép xóa loại ""%1"", 
						           | vì các giá trị bổ sung đã được nhập.
						           |Trước tiên, phải xóa các giá trị bổ sung đã nhập.
						           |
						           |Việc xóa đã bị hủy.';
						           |ru = 'Недопустимо удалять тип ""%1"",
						           |так как дополнительные значения уже введены.
						           |Сначала нужно удалить введенные дополнительные значения.
						           |
						           |Удаление отменено.';
						           |en = 'Cannot delete the ""%1"" type
						           |as additional values are already entered.
						           |Please delete the additional values first.
						           |
						           |The deletion is canceled.'; fa = 'Cannot delete the ""%1"" type
						           |as additional values are already entered.
						           |Please delete the additional values first.
						           |
						           |The deletion is canceled.';
						           |it = 'Non è consentito eliminare il tipo ""%1"",
						           | in quanto i valori aggiuntivi sono già stati inseriti.
						           |Prima devono essere eliminati i valori aggiuntivi.
						           |
						           |Eliminazione annullata.';
						           |pl = 'Usuwanie typu ""%1"" jest niedozwolone,
						           |ponieważ dodatkowe wartości zostały już wprowadzone.
						           |Najpierw należy usunąć wprowadzone wartości dodatkowe.
						           |
						           |Usunięcie jest anulowane.';
						           |tr = '""%1"" türü silinemez,
						           |çünkü ek değerler artık girildi.
						           |Önce ek değerlerin silinmesi gerekiyor.
						           |
						           |Silinme iptal edildi.'"),
						String(Type("CatalogRef.ObjectsPropertiesValues")) );
					
					Object.ValueType = New TypeDescription(
						Object.ValueType,
						"CatalogRef.ObjectsPropertiesValues",
						"CatalogRef.ObjectPropertyValueHierarchy");
				EndIf;
			EndIf;
		EndIf;
		
		// Checking that not more than one additional value type is set.
		If Object.ValueType.ContainsType(Type("CatalogRef.ObjectPropertyValueHierarchy"))
		   And Object.ValueType.ContainsType(Type("CatalogRef.ObjectsPropertiesValues")) Then
			
			If Not OldValueType.ContainsType(Type("CatalogRef.ObjectPropertyValueHierarchy")) Then
				
				WarningText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Không được phép sử dụng đồng thời các kiểu giá trị
					           |""%1"" và 
					           | ""%2"". 
					           |
					           |Đã xóa kiểu thứ hai.';
					           |ru = 'Недопустимо одновременно использовать типы значения
					           |""%1"" и
					           |""%2"".
					           |
					           |Второй тип удален.';
					           |en = 'Cannot use both
					           |""%1"" and
					           |""%2"" value types at the same time.
					           |
					           |The second type is deleted.'; fa = 'Cannot use both
					           |""%1"" and
					           |""%2"" value types at the same time.
					           |
					           |The second type is deleted.';
					           |it = 'Non è consentito utilizzare i tipi dei valori
					           |""%1"" e ""%2""
					           |contemporaneamente.
					           |
					           |Il secondo tipo è stato cancellato.';
					           |pl = 'Jednoczesne wykorzystywanie typów wartości
					           |""%1"" i
					           |""%2"" jest niedozwolone.
					           |
					           |Drugi typ został usunięty.';
					           |tr = 'Aynı zamanda 
					           |""%1"" ve
					           |""%2"".
					           |
					           | değerin tipleri kullanılamaz. İkinci tip silindi.'"),
					String(Type("CatalogRef.ObjectsPropertiesValues")),
					String(Type("CatalogRef.ObjectPropertyValueHierarchy")) );
				
				// Deletion of the second type.
				Object.ValueType = New TypeDescription(
					Object.ValueType,
					,
					"CatalogRef.ObjectPropertyValueHierarchy");
			Else
				WarningText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Không được phép sử dụng đồng thời các kiểu giá trị
					           |""%1"" và
					           |""%2"".
					           |
					           |Đã xóa kiểu thứ nhất.';
					           |ru = 'Недопустимо одновременно использовать типы значения
					           |""%1"" и
					           |""%2"".
					           |
					           |Первый тип удален.';
					           |en = 'Cannot use both
					           |""%1"" and
					           |""%2"" value types at the same time.
					           |
					           |The first type is deleted.'; fa = 'Cannot use both
					           |""%1"" and
					           |""%2"" value types at the same time.
					           |
					           |The first type is deleted.';
					           |it = 'Non è consentito utilizzare i tipi dei valori
					           |""%1"" e ""%2""
					           |contemporaneamente.
					           |
					           |Il primo tipo è stato cancellato.';
					           |pl = 'Jednoczesne wykorzystywanie typów wartości
					           |""%1"" i
					           |""%2"" jest niedozwolone.
					           |
					           |Pierwszy typ został usunięty.';
					           |tr = 'Aynı zamanda 
					           |""%1"" ve
					           |""%2"".
					           |
					           | değerin tipleri kullanılamaz. Birinci tip silindi.'"),
					String(Type("CatalogRef.ObjectsPropertiesValues")),
					String(Type("CatalogRef.ObjectPropertyValueHierarchy")) );
				
				// Deletion of the first type.
				Object.ValueType = New TypeDescription(
					Object.ValueType,
					,
					"CatalogRef.ObjectsPropertiesValues");
			EndIf;
		EndIf;
		
		ValuesOwner = Object.Ref;
		ValuesWithWeight   = Object.AdditionalValuesWithWeight;
	EndIf;
	
	If PropertyManagerInternal.ValueTypeContainsPropertyValues(Object.ValueType) Then
		Items.ValueFormsHeadersGroup.Visible = True;
		Items.AdditionalValuesWithWeight.Visible = True;
		Items.ValuePage.Visible = True;
		Items.Pages.PagesRepresentation = FormPagesRepresentation.TabsOnTop;
	Else
		Items.ValueFormsHeadersGroup.Visible = False;
		Items.AdditionalValuesWithWeight.Visible = False;
		Items.ValuePage.Visible = False;
		Items.Pages.PagesRepresentation = FormPagesRepresentation.None;
	EndIf;
	
	Items.Values.Header        = ValuesWithWeight;
	Items.ValuesWeight.Visible = ValuesWithWeight;
	
	CommonClientServer.SetDynamicListFilterItem(
		Values, "Owner", ValuesOwner, , , True);
	
	If Object.ValueType.ContainsType(Type("CatalogRef.ObjectsPropertiesValues")) Then
		ListProperties = Common.DynamicListPropertiesStructure();
		ListProperties.QueryText =
			"SELECT
			|	Values.Ref,
			|	Values.DataVersion,
			|	Values.DeletionMark,
			|	Values.Predefined,
			|	Values.Owner,
			|	Values.Parent,
			|	Values.Description AS Description,
			|	Values.Weight
			|FROM
			|	Catalog.ObjectsPropertiesValues AS Values";
		ListProperties.MainTable = "Catalog.ObjectsPropertiesValues";
		
		CurrentLanguageSuffix = Common.CurrentUserLanguageSuffix();
		If CurrentLanguageSuffix = Undefined Then
			
			ListProperties.QueryText = ListProperties.QueryText + "
			|	LEFT JOIN Catalog.ObjectsPropertiesValues.Presentations AS PresentationValues
			|		ON (PresentationValues.Ref = Values.Ref)
			|		AND PresentationValues.LanguageCode = &LanguageCode";
			
			ListProperties.QueryText  = StrReplace(ListProperties.QueryText, "Values.Description AS Description", 
				"CAST(ISNULL(PresentationValues.Description, Values.Description) AS STRING(150)) AS Description");
			
		ElsIf ValueIsFilled(CurrentLanguageSuffix) 
				And Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
					ModuleNationalLanguageSupportServer = Common.CommonModule("NationalLanguageSupportServer");
					ModuleNationalLanguageSupportServer.ChangeRequestFieldUnderCurrentLanguage(ListProperties.QueryText, "Values.Description");
		EndIf;
		
		Common.SetDynamicListProperties(Items.Values,
			ListProperties);
	Else
		ListProperties = Common.DynamicListPropertiesStructure();
		ListProperties.QueryText =
			"SELECT
			|	Values.Ref,
			|	Values.DataVersion,
			|	Values.DeletionMark,
			|	Values.Predefined,
			|	Values.Owner,
			|	Values.Parent,
			|	Values.Description AS Description,
			|	Values.Weight
			|FROM
			|	Catalog.ObjectPropertyValueHierarchy AS Values";
		ListProperties.MainTable = "Catalog.ObjectPropertyValueHierarchy";
		
		CurrentLanguageSuffix = Common.CurrentUserLanguageSuffix();
		If CurrentLanguageSuffix = Undefined Then
			
			ListProperties.QueryText = ListProperties.QueryText + "
			|	LEFT JOIN Catalog.ObjectPropertyValueHierarchy.Presentations AS PresentationValues
			|		ON (PresentationValues.Ref = Values.Ref)
			|		AND PresentationValues.LanguageCode = &LanguageCode";
			
			ListProperties.QueryText  = StrReplace(ListProperties.QueryText, "Values.Description AS Description", 
				"CAST(ISNULL(PresentationValues.Description, Values.Description) AS STRING(150)) AS Description");
			
		ElsIf ValueIsFilled(CurrentLanguageSuffix) 
			And Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
				ModuleNationalLanguageSupportServer = Common.CommonModule("NationalLanguageSupportServer");
				ModuleNationalLanguageSupportServer.ChangeRequestFieldUnderCurrentLanguage(ListProperties.QueryText, "Values.Description");
		EndIf;
		
		Common.SetDynamicListProperties(Items.Values, ListProperties);
	EndIf;
	
	CommonClientServer.SetDynamicListParameter(
		Values, "LanguageCode", CurrentLanguage().LanguageCode, True);
	
	If Not ValueIsFilled(Object.AdditionalValuesOwner) Then
		Items.ValueListAdjustment.Visible = False;
		Items.AdditionalValues.ReadOnly = False;
		Items.ValuesEditingCommandBar.Visible = True;
		Items.ValuesEditingContextMenu.Visible = True;
		Items.AdditionalValuesWithWeight.Visible = True;
	Else
		Items.ValueListAdjustment.Visible = True;
		Items.AdditionalValues.ReadOnly = True;
		Items.ValuesEditingCommandBar.Visible = False;
		Items.ValuesEditingContextMenu.Visible = False;
		Items.AdditionalValuesWithWeight.Visible = False;
		
		Items.ValueListAdjustmentComment.Hyperlink = ValueIsFilled(Object.Ref);
		Items.ValueListAdjustmentChange.Enabled    = ValueIsFilled(Object.Ref);
		
		OwnerProperties = Common.ObjectAttributesValues(
			Object.AdditionalValuesOwner, "Title, PropertyKind1");
		
		If OwnerProperties.PropertyKind1 = Enums.PropertiesKinds.AdditionalInfo Then
			AdjustmentTemplate = NStr("vi = 'Danh sách giá trị chung với thông tin ""%1""';
										|ru = 'Список значений общий со сведением ""%1""';
										|en = 'The value list is shared with the ""%1"" information record'; fa = 'The value list is shared with the ""%1"" information record';
										|it = 'Elenco di valori in comune con l''informazione ""%1""';
										|pl = 'Lista wartości wspólna z informacją ""%1""';
										|tr = '""%1"" bilgiye sahip ortak değer listesi'");
		ElsIf OwnerProperties.PropertyKind1 = Enums.PropertiesKinds.Labels Then
			AdjustmentTemplate = NStr("vi = 'Danh sách giá trị chung có nhãn đánh dấu ""%1""';
										|ru = 'Список значений общий с меткой ""%1""';
										|en = 'The value list is shared with the ""%1"" label'; fa = 'The value list is shared with the ""%1"" label';
										|it = 'Список значений общий с меткой ""%1""';
										|pl = 'The value list is shared with the ""%1"" label';
										|tr = '""%1"" etiketine sahip ortak değer listesi'");
		Else
			AdjustmentTemplate = NStr("vi = 'Danh sách giá trị chung với mục tin ""%1""';
										|ru = 'Список значений общий с реквизитом ""%1""';
										|en = 'The value list is shared with the ""%1"" attribute'; fa = 'The value list is shared with the ""%1"" attribute';
										|it = 'Elenco di valori in comune con il requisito ""%1""';
										|pl = 'Lista wartości wspólna z atrybutem ""%1""';
										|tr = '""%1"" özniteliğine sahip ortak değer listesi'");
		EndIf;
		
		Items.ValueListAdjustmentComment.Title =
			StringFunctionsClientServer.SubstituteParametersToString(AdjustmentTemplate, OwnerProperties.Title);
	EndIf;
	
	RefreshSetsList();
	
	If Not ShowSetAdjustment And SetsList.Count() < 2 Then
		
		Items.SetsAdjustment.Visible = False;
	Else
		Items.SetsAdjustment.Visible = True;
		Items.SetsAdjustmentComment.Hyperlink = True;
		
		Items.SetsAdjustmentChange.Enabled = ValueIsFilled(Object.Ref);
		
		If SetsList.Count() < 2 Then
			
			Items.SetsAdjustmentChange.Visible = False;
		
		ElsIf ValueIsFilled(CurrentPropertiesSet) Then
			Items.SetsAdjustmentChange.Visible = True;
		Else
			Items.SetsAdjustmentChange.Visible = False;
		EndIf;
		
		If SetsList.Count() = 0 Then
			Items.SetsAdjustmentComment.Hyperlink = False;
			Items.SetsAdjustmentChange.Visible = False;
			
			If Object.PropertyKind1 = Enums.PropertiesKinds.AdditionalInfo
				Or Object.IsAdditionalInfo Then
				CommentText1 = NStr("vi = 'Thông tin không được bao gồm trong các bộ';
									|ru = 'Сведение не входит в наборы';
									|en = 'The information record is not included in any sets'; fa = 'The information record is not included in any sets';
									|it = 'Informazione non fa parte della selezione';
									|pl = 'Informacja nie wchodzi do składu zestawów';
									|tr = 'Bilgi kümelere dahil deyil'");
			ElsIf Object.PropertyKind1 = Enums.PropertiesKinds.Labels Then
				CommentText1 = NStr("vi = 'Nhãn đánh dấu không nằm trong tập hợp';
									|ru = 'Метка не входит в наборы';
									|en = 'The label is not included in any sets'; fa = 'The label is not included in any sets';
									|it = 'Метка не входит в наборы';
									|pl = 'The label is not included in any sets';
									|tr = 'Etiket kümeye dahil değildir'");
			Else
				CommentText1 = NStr("vi = 'Mục tin không nằm trong tập hợp';
									|ru = 'Реквизит не входит в наборы';
									|en = 'The attribute is not included in any sets'; fa = 'The attribute is not included in any sets';
									|it = 'Requisito non fa parte della selezione';
									|pl = 'Atrybut nie wchodzi do składu zestawów';
									|tr = 'Öznitelik kümelere dahil deyil'");
			EndIf;
		ElsIf SetsList.Count() < 2 Then
			If Object.PropertyKind1 = Enums.PropertiesKinds.AdditionalInfo
				Or Object.IsAdditionalInfo Then
				AdjustmentTemplate = NStr("vi = 'Thông tin nằm trong tập hợp: %1';
											|ru = 'Сведение входит в набор: %1';
											|en = 'The information record is included in the set: %1'; fa = 'The information record is included in the set: %1';
											|it = 'L''informazione fa parte del set: %1';
											|pl = 'Informacja wchodzi do zestawu: %1';
											|tr = 'Verinin dahil olduğu küme: %1'");
			ElsIf Object.PropertyKind1 = Enums.PropertiesKinds.Labels Then
				AdjustmentTemplate = NStr("vi = 'Nhãn đánh dấu nằm trong tập hợp: %1';
											|ru = 'Метка входит в набор: %1';
											|en = 'The label is included in the set: %1'; fa = 'The label is included in the set: %1';
											|it = 'Метка входит в набор: %1';
											|pl = 'The label is included in the set: %1';
											|tr = 'Etiket kümeye dahildir: %1'");
			Else
				AdjustmentTemplate = NStr("vi = 'Mục tin nằm trong tập hợp: %1';
											|ru = 'Реквизит входит в набор: %1';
											|en = 'The attribute is included in the set: %1'; fa = 'The attribute is included in the set: %1';
											|it = 'Il requisito fa parte del set: %1';
											|pl = 'Atrybut wchodzi w skład zestawu: %1';
											|tr = 'Özelliğin ait olduğu küme: %1'");
			EndIf;
			CommentText1 = StringFunctionsClientServer.SubstituteParametersToString(AdjustmentTemplate, TrimAll(SetsList[0].Presentation));
		Else
			If Object.PropertyKind1 = Enums.PropertiesKinds.AdditionalInfo
				Or Object.IsAdditionalInfo Then
				AdjustmentTemplate = NStr("vi = 'Thông tin bao gồm trong %1 %2';
											|ru = 'Сведение входит в %1 %2';
											|en = 'The information record is included in %1 %2'; fa = 'The information record is included in %1 %2';
											|it = 'Informazione fa parte di %1 %2';
											|pl = 'Informacje są zawarte w %1 %2';
											|tr = 'Bilgi %1 %2 dahil edildi'");
			ElsIf Object.PropertyKind1 = Enums.PropertiesKinds.Labels Then
				AdjustmentTemplate = NStr("vi = 'Nhãn đánh dấu nằm trong %1 %2';
											|ru = 'Метка входит в %1 %2';
											|en = 'The label is included in %1 %2'; fa = 'The label is included in %1 %2';
											|it = 'Метка входит в %1 %2';
											|pl = 'The label is included in %1 %2';
											|tr = 'Etiket %1 %2 içindedir'");
			Else
				AdjustmentTemplate = NStr("vi = 'Mục tin nằm trong : %1 %2';
											|ru = 'Реквизит входит в %1 %2';
											|en = 'The attribute is included in %1 %2'; fa = 'The attribute is included in %1 %2';
											|it = 'Requisito fa parte di %1 %2';
											|pl = 'Atrybut wchodzi w skład %1 %2';
											|tr = 'Öznitelik %1 %2 dahil edildi'");
			EndIf;
			
			StringSets = UsersInternalClientServer.IntegerSubject(SetsList.Count(),
				"", NStr("vi = 'bộ,bộ,bộ,,,,,,0';
						|ru = 'набор,набора,наборов,,,,,,0';
						|en = 'set,sets,,,0'; fa = 'set,sets,,,0';
						|it = 'set, del set, dei set,,,,,,0';
						|pl = 'zestaw,zestawu,zestawów,,,,,,0';
						|tr = 'küme, kümeler, kümeler,,,,,,0'"));
			
			CommentText1 = StringFunctionsClientServer.SubstituteParametersToString(AdjustmentTemplate, Format(SetsList.Count(), "NG="), StringSets);
		EndIf;
		
		Items.SetsAdjustmentComment.Title = CommentText1 + " ";
		
		If Items.SetsAdjustmentComment.Hyperlink Then
			Items.SetsAdjustmentComment.ToolTip = NStr("vi = 'Chuyển đến tập hợp';
														|ru = 'Переход к набору';
														|en = 'Go to set.'; fa = 'Go to set.';
														|it = 'Passaggio al set';
														|pl = 'Przejście do zestawu';
														|tr = 'Kümeye git'");
		Else
			Items.SetsAdjustmentComment.ToolTip = "";
		EndIf;
	EndIf;
	
	Items.FillIDForFormulas.Enabled = Not Items.IDForFormulas.ReadOnly;
	
EndProcedure

&AtServer
Procedure SwitchAttributeDisplaySettings(ValueType)
	
	AllowMultilineFieldChoice = (Object.ValueType.Types().Count() = 1)
		And (Object.ValueType.ContainsType(Type("String")));
	AllowDisplayAsHyperlink   = AllowMultilineFieldChoice
		Or (Not Object.ValueType.ContainsType(Type("String"))
			And Not Object.ValueType.ContainsType(Type("Date"))
			And Not Object.ValueType.ContainsType(Type("Boolean"))
			And Not Object.ValueType.ContainsType(Type("Number")));
	
	Items.SingleLineKind.Visible                       = AllowMultilineFieldChoice;
	Items.MultilineInputFieldGroupSettings.Visible = AllowMultilineFieldChoice;
	Items.OutputAsHyperlink.Visible              = AllowDisplayAsHyperlink;
	
EndProcedure

&AtServer
Procedure ClearEnteredWeightCoefficients()
	
	If Object.ValueType.ContainsType(Type("CatalogRef.ObjectsPropertiesValues")) Then
		ValueTableName = "Catalog.ObjectsPropertiesValues";
	Else
		ValueTableName = "Catalog.ObjectPropertyValueHierarchy";
	EndIf;
	
	Block = New DataLock;
	Block.Add(ValueTableName);
	
	BeginTransaction();
	Try
		Block.Lock();
		Query = New Query;
		Query.Text =
		"SELECT
		|	CurrentTable.Ref AS Ref
		|FROM
		|	Catalog.ObjectsPropertiesValues AS CurrentTable
		|WHERE
		|	CurrentTable.Weight <> 0";
		Query.Text = StrReplace(Query.Text , "Catalog.ObjectsPropertiesValues", ValueTableName);
		
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			ValueObject = Selection.Ref.GetObject();// CatalogObject.ObjectsPropertiesValues
			ValueObject.Weight = 0;
			ValueObject.Write();
		EndDo;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

&AtServer
Procedure RefreshSetsList()
	
	SetsList.Clear();
	
	If ValueIsFilled(Object.Ref) Then
		
		Query = New Query(
		"SELECT
		|	AdditionalAttributes.Ref AS Set,
		|	AdditionalAttributes.Ref.Description
		|FROM
		|	Catalog.AdditionalAttributesAndInfoSets.AdditionalAttributes AS AdditionalAttributes
		|WHERE
		|	AdditionalAttributes.Property = &Property
		|	AND NOT AdditionalAttributes.Ref.IsFolder
		|
		|UNION ALL
		|
		|SELECT
		|	AdditionalInfo.Ref,
		|	AdditionalInfo.Ref.Description
		|FROM
		|	Catalog.AdditionalAttributesAndInfoSets.AdditionalInfo AS AdditionalInfo
		|WHERE
		|	AdditionalInfo.Property = &Property
		|	AND NOT AdditionalInfo.Ref.IsFolder");
		
		Query.SetParameter("Property", Object.Ref);
		
		BeginTransaction();
		Try
			Selection = Query.Execute().Select();
			While Selection.Next() Do
				SetsList.Add(Selection.Set, Selection.Description + "         ");
			EndDo;
			
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnCurrentPageChange(Direction, BasicPage, CurrentPage)
	
	BasicPage.CurrentPage = CurrentPage;
	If CurrentPage = Items.ActionChoice Then
		If Direction = "GoForward" Then
			SelectedElement = Items.Properties.CurrentData;
			PassedFormParameters.AdditionalValuesOwner = SelectedElement.Property;
			FillActionListOnAddAttribute();
		EndIf;
	ElsIf CurrentPage = Items.AttributeCard Then
		FillPropertyCard();
	EndIf;
	
EndProcedure

&AtServer
Function AttributeWithAdditionalValuesList()
	
	AttributeWithAdditionalValuesList = True;
	OwnerProperties = Common.ObjectAttributesValues(
		PassedFormParameters.AdditionalValuesOwner, "ValueType");
	If Not OwnerProperties.ValueType.ContainsType(Type("CatalogRef.ObjectsPropertiesValues"))
		And Not OwnerProperties.ValueType.ContainsType(Type("CatalogRef.ObjectPropertyValueHierarchy")) Then
		AttributeWithAdditionalValuesList = False;
	EndIf;
	
	Return AttributeWithAdditionalValuesList;
EndFunction

&AtServer
Procedure FillActionListOnAddAttribute()
	
	AttributeWithAdditionalValuesList = AttributeWithAdditionalValuesList();
	
	If PassedFormParameters.PropertyKind1 = Enums.PropertiesKinds.AdditionalInfo Then
		AddCommon = NStr("vi = 'Thêm dữ liệu theo nguyên trạng (được khuyến nghị)
			|
			|Trong trường hợp này, có thể chọn dữ liệu thuộc các loại khác nhau trong danh sách và báo cáo.';
			|ru = 'Добавить сведение как есть (рекомендуется)
			|
			|В этом случае будет возможно отбирать по нему данные разных типов в списках и отчетах.';
			|en = 'Add the information record ""as is"" (recommended)
			|
			|You can use this information record to filter data of different types in lists and reports.'; fa = 'Add the information record ""as is"" (recommended)
			|
			|You can use this information record to filter data of different types in lists and reports.';
			|it = 'Aggiungere l''informazione così com''è (consigliato)
			|
			| In questo caso sarà possibile selezionarvi dati di tipi diversi in elenchi e report.';
			|pl = 'Dodaj informacje jak jest (zaleca się)
			|
			|W tym przypadku będzie możliwy wybór wg niego różnych typów w listach i raportach.';
			|tr = 'Bilgiyi olduğu gibi ekle (tavsiye edilen)
			|
			|Bu durumda liste ve raporlarda farklı türde veriler kümeye dayalı olarak seçilebilecek.'");
		MakeBySample = NStr("vi = 'Tạo bản sao thông tin theo mẫu (với danh sách giá trị chung) 
			|
			|Danh sách giá trị của thông tin này sẽ được chia sẻ với thông tin gốc.
			|Tùy chọn này thuận tiện cho việc cài đặt tập trung danh sách giá trị cho nhiều thông tin cùng loại cùng một lúc.
			|Trong trường hợp này, có thể chỉnh sửa tên và một số thuộc tính trộn khác.';
			|ru = 'Сделать копию сведения по образцу (с общим списком значений)
			|
			|Список значений этого сведения будет общим с исходным сведением.
			|С помощью этого варианта удобно выполнять централизованную настройку списка значений сразу для нескольких однотипных сведений.
			|При этом можно отредактировать наименование и ряд других свойств сведения.';
			|en = 'Copy the information record from a master record (with a shared value list)
			|
			|Both records will share a value list.
			|This option is recommended to configure values for similar information records.
			|You can edit the record description and some other properties.'; fa = 'Copy the information record from a master record (with a shared value list)
			|
			|Both records will share a value list.
			|This option is recommended to configure values for similar information records.
			|You can edit the record description and some other properties.';
			|it = 'Creare una copia dell''informazione secondo il modello (con un elenco comune di valori) 
			|
			| Elenco di valori di questa informazione sarà comune con l''informazione iniziale.
			| Con questa opzione è facile eseguire un''impostazione centralizzata dell''elenco di valori per diverse informazioni dello stesso tipo contemporaneamente.
			| Inoltre è possibile modificare il nome o altre caratteristiche dell''informazione.';
			|pl = 'Utwórz kopię informacji wg wzoru (ze wspólną listą wartości)
			|
			|Lista wartości tej informacji będzie wspólna z danymi źródłowymi.
			|Przy pomocy tego wariantu można wygodnie wykonywać scentralizowaną konfigurację listy wartości od razu dla kilku informacji tego samego typu.
			|Przy czym jest możliwa edycja nazw i wielu innych właściwości informacji.';
			|tr = 'Örnek bazında (ortak bir değer listesi olan) bilginin bir kopyasını yap
			|
			|Bu bilginin değer listesi kaynak bilgiyle ortak olacaktır.
			|Bu varyasyonla, birden çok tek tip bilgi için bir kerede merkezi bir değer listesi ayarını yapmak için kullanılabilir.
			|Bu durumda, bilginin adı ve diğer özelliklerini düzenleyebilirsiniz.'");
		If AttributeWithAdditionalValuesList Then
			CreateByCopying = NStr("vi = 'Tạo bản sao thông tin
				|
				|Sẽ tạo bản sao thông tin và tất cả giá trị của nó.';
				|ru = 'Сделать копию сведения
				|
				|Будет создана копия сведения и всех его значений.';
				|en = 'Copy the information record
				|
				|A copy of the information record and all its values will be created.'; fa = 'Copy the information record
				|
				|A copy of the information record and all its values will be created.';
				|it = 'Сделать копию сведения
				|
				|Будет создана копия сведения и всех его значений.';
				|pl = 'Copy the information record
				|
				|A copy of the information record and all its values will be created.';
				|tr = 'Bilgileri kopyala
				|
				|Bilgilerin ve tüm değerlerinin kopyası oluşturulacak.'")
		Else
			CreateByCopying = NStr("vi = 'Tạo bản sao thông tin
				|
				|Sẽ tạo bản sao thông tin.';
				|ru = 'Сделать копию сведения
				|
				|Будет создана копия сведения.';
				|en = 'Copy the information record
				|
				|A copy of the information record will be created.'; fa = 'Copy the information record
				|
				|A copy of the information record will be created.';
				|it = 'Сделать копию сведения
				|
				|Будет создана копия сведения.';
				|pl = 'Copy the information record
				|
				|A copy of the information record will be created.';
				|tr = 'Bilgileri kopyala
				|
				|Bilgilerin kopyası oluşturulacak.'");
		EndIf;
	ElsIf PassedFormParameters.PropertyKind1 = Enums.PropertiesKinds.Labels Then
		AddCommon = NStr("vi = 'Thêm nhãn vốn có (nên dùng)
			|
			|Trong trường hợp này sẽ có thể lọc dữ liệu các kiểu khác nhau trong danh sách và báo cáo theo nhãn này.';
			|ru = 'Добавить метку как есть (рекомендуется)
			|
			|В этом случае будет возможно отбирать по ней данные разных типов в списках и отчетах.';
			|en = 'Add the label ""as is"" (recommended)
			|
			|You can use this label to filter data of different types in lists and reports.'; fa = 'Add the label ""as is"" (recommended)
			|
			|You can use this label to filter data of different types in lists and reports.';
			|it = 'Добавить метку как есть (рекомендуется)
			|
			|В этом случае будет возможно отбирать по ней данные разных типов в списках и отчетах.';
			|pl = 'Add the label ""as is"" (recommended)
			|
			|You can use this label to filter data of different types in lists and reports.';
			|tr = 'Etiketi olduğu gibi ekle (önerilmektedir)
			|
			|Bu durumda, listelerde ve raporlardaki bunun farklı tiplerdeki verilerini seçmek mümkün olacaktır.'");
		CreateByCopying = NStr("vi = 'Tạo bản sao nhãn
			|
			|Sẽ tạo bản sao nhãn';
			|ru = 'Сделать копию метки
			|
			|Будет создана копия метки';
			|en = 'Copy the label
			|
			|A copy of the label will be created.'; fa = 'Copy the label
			|
			|A copy of the label will be created.';
			|it = 'Сделать копию метки
			|
			|Будет создана копия метки';
			|pl = 'Copy the label
			|
			|A copy of the label will be created.';
			|tr = 'Etiketi kopyala
			|
			|Etiketin kopyası oluşturulacaktır'");
	Else
		AddCommon = NStr("vi = 'Thêm mục tin theo nguyên trạng (được khuyến nghị)
			|
			|Trong trường hợp này, có thể chọn dữ liệu thuộc các loại khác nhau trong danh sách và báo cáo.';
			|ru = 'Добавить реквизит как есть (рекомендуется)
			|
			|В этом случае будет возможно отбирать по нему данные разных типов в списках и отчетах.';
			|en = 'Add the attribute ""as is"" (recommended)
			|
			|You can use this attribute to filter data of different types in lists and reports.'; fa = 'Add the attribute ""as is"" (recommended)
			|
			|You can use this attribute to filter data of different types in lists and reports.';
			|it = 'Aggiungere il requisito così com''è (consigliato)
			|
			| In questo caso sarà possibile selezionarvi dati di tipi diversi in elenchi e report.';
			|pl = 'Dodaj atrybut jak jest (zaleca się)
			|
			|W tym przypadku będzie możliwy wybór wg niego różnych typów w listach i raportach.';
			|tr = 'Özniteliği olduğu gibi ekle (tavsiye edilen)
			|
			|Bu durumda liste ve raporlarda farklı türde veriler kümeye dayalı olarak seçilebilecek.'");
		MakeBySample = NStr("vi = 'Tạo bản sao mục tin theo mẫu (với danh sách giá trị chung) 
			|
			|Danh sách giá trị của mục tin này sẽ được chia sẻ với thông tin gốc.
			|Tùy chọn này thuận tiện cho việc cài đặt tập trung danh sách giá trị cho nhiều mục tin cùng loại cùng một lúc.
			|Trong trường hợp này, có thể chỉnh sửa tên và một số mục tin khác.';
			|ru = 'Сделать копию реквизита по образцу (с общим списком значений)
			|
			|Список значений этого реквизита будет общим с исходным реквизитом.
			|С помощью этого варианта удобно выполнять централизованную настройку списка значений сразу для нескольких однотипных реквизитов.
			|При этом можно отредактировать наименование и ряд других свойств реквизита.';
			|en = 'Copy the attribute from a master attribute (with a shared value list)
			|
			|Both attributes will share a value list.
			|This option is recommended to configure values for similar attributes.
			|You can edit the attribute description and some other properties.'; fa = 'Copy the attribute from a master attribute (with a shared value list)
			|
			|Both attributes will share a value list.
			|This option is recommended to configure values for similar attributes.
			|You can edit the attribute description and some other properties.';
			|it = 'Creare una copia del requisito secondo il modello (con un elenco comune di valori)
			|
			|L''elenco dei valori di questo requisito sarà comune con il requisito iniziale.
			|Con questa opzione, è facile eseguire un''impostazione centralizzata dell''elenco di valori per diversi requisiti dello stesso tipo contemporaneamente.
			|Sarà anche possibile modificare il nome o altre proprietà del requisito.';
			|pl = 'Utwórz kopię atrybutu wg wzoru (ze wspólną listą wartości)
			|
			|Lista wartości tego atrybutu będzie wspólna z atrybutem źródłowym.
			|Przy pomocy tego wariantu można wygodnie wykonywać scentralizowaną konfigurację listy wartości od razu dla kilku atrybutów tego samego typu.
			|Przy czym jest możliwa edycja nazw i wielu innych właściwości atrybutu.';
			|tr = 'Örnek bazında (ortak bir değer listesi olan) özniteliğin bir kopyasını yap
			|
			|Bu özniteliğin değer listesi kaynak öznitelikle ortak olacaktır.
			|Bu varyasyonla, birden çok tek tip öznitelik için bir kerede merkezi bir değer listesi ayarını yapmak için kullanılabilir.
			|Bu durumda, özniteliğin adı ve diğer özelliklerini düzenleyebilirsiniz.'");
		If AttributeWithAdditionalValuesList Then
			CreateByCopying = NStr("vi = 'Tạo bản sao mục tin
				|
				|Sẽ tạo bản sao mục tin và tất cả giá trị của nó.';
				|ru = 'Сделать копию реквизита
				|
				|Будет создана копия реквизита и всех его значений.';
				|en = 'Copy the attribute
				|
				|A copy of the attribute and all its values will be created.'; fa = 'Copy the attribute
				|
				|A copy of the attribute and all its values will be created.';
				|it = 'Сделать копию реквизита
				|
				|Будет создана копия реквизита и всех его значений.';
				|pl = 'Copy the attribute
				|
				|A copy of the attribute and all its values will be created.';
				|tr = 'Özniteliği kopyala
				|
				|Özniteliğin ve tüm değerlerinin kopyası oluşturulacak.'");
		Else
			CreateByCopying = NStr("vi = 'Tạo bản sao mục tin
				|
				|Sẽ tạo bản sao mục tin.';
				|ru = 'Сделать копию реквизита
				|
				|Будет создана копия реквизита.';
				|en = 'Copy the attribute
				|
				|A copy of the attribute will be created.'; fa = 'Copy the attribute
				|
				|A copy of the attribute will be created.';
				|it = 'Сделать копию реквизита
				|
				|Будет создана копия реквизита.';
				|pl = 'Copy the attribute
				|
				|A copy of the attribute will be created.';
				|tr = 'Özniteliği kopyala
				|
				|Özniteliğin kopyası oluşturulacak.'");
		EndIf;
	EndIf;
	
	ChoiceList = Items.AttributeAddMode.ChoiceList;
	ChoiceList.Clear();
	
	ChoiceList.Add("AddCommonAttributeToSet", AddCommon);
	If AttributeWithAdditionalValuesList Then
		ChoiceList.Add("CreateBySample", MakeBySample);
	EndIf;
	ChoiceList.Add("CreateByCopying", CreateByCopying);
	
	AttributeAddMode = "AddCommonAttributeToSet";
	
EndProcedure

&AtServer
Procedure WriteAdditionalAttributeValuesOnCopy(CurrentObject)
	
	If CurrentObject.ValueType.ContainsType(Type("CatalogRef.ObjectPropertyValueHierarchy")) Then
		Parent = Catalogs.ObjectPropertyValueHierarchy.EmptyRef();
	Else
		Parent = Catalogs.ObjectsPropertiesValues.EmptyRef();
	EndIf;
	
	Owner = CurrentObject.Ref;
	TreeRow = AdditionalAttributesValues.GetItems();
	WriteAdditionalAttributeValuesOnCopyRecursively(Owner, TreeRow, Parent);
	TreeRow.Clear();
	Items.AttributeValuePages.CurrentPage = Items.AdditionalValues;
	
EndProcedure

&AtServer
Procedure WriteAdditionalAttributeValuesOnCopyRecursively(Owner, TreeRow, Parent)
	
	For Each TreeItem In TreeRow Do
		ObjectCopy = TreeItem.Ref.GetObject().Copy();
		ObjectCopy.Owner = Owner;
		ObjectCopy.Parent = Parent;
		ObjectCopy.Write(); // ACC:1327 New object record.
		
		SubordinateItems = TreeItem.GetItems();
		WriteAdditionalAttributeValuesOnCopyRecursively(Owner, SubordinateItems, ObjectCopy.Ref)
	EndDo;
	
EndProcedure

&AtServer
Procedure SetHyperlinkTitles()
	
	AvailabilityDependenceDefined              = False;
	RequiredFillingDependenceDefined = False;
	VisibilityDependenceDefined                = False;
	
	FilterBySet = New Structure;
	FilterBySet.Insert("PropertiesSet", CurrentPropertiesSet);
	FoundDependencies = Object.AdditionalAttributesDependencies.FindRows(FilterBySet);
	
	For Each PropertyDependence In FoundDependencies Do
		If PropertyDependence.DependentProperty = "Available" Then
			AvailabilityDependenceDefined = True;
		ElsIf PropertyDependence.DependentProperty = "RequiredToFill" Then
			RequiredFillingDependenceDefined = True;
		ElsIf PropertyDependence.DependentProperty = "isVisible" Then
			VisibilityDependenceDefined = True;
		EndIf;
	EndDo;
	
	TemplateDependenceDefined = NStr("vi = 'với điều kiện';
									|ru = 'с условием';
									|en = 'conditionally'; fa = 'conditionally';
									|it = 'a condizione';
									|pl = 'ze stanem';
									|tr = 'koşulu ile'");
	TemplateDependenceNotDefined = NStr("vi = 'luôn luôn';
										|ru = 'всегда';
										|en = 'always'; fa = 'همیشه';
										|it = 'sempre';
										|pl = 'zawsze';
										|tr = 'her zaman'");
	
	Items.ChooseAvailabilityOption.Title = ?(AvailabilityDependenceDefined,
		TemplateDependenceDefined,
		TemplateDependenceNotDefined);
	
	Items.ChooseItemRequiredOption.Title = ?(RequiredFillingDependenceDefined,
		TemplateDependenceDefined,
		TemplateDependenceNotDefined);
	
	Items.ChooseVisibilityOption.Title = ?(VisibilityDependenceDefined,
		TemplateDependenceDefined,
		TemplateDependenceNotDefined);
	
EndProcedure

&AtClient
Procedure OpenDependenceSettingForm(PropertyToConfigure)
	
	FormParameters = New Structure;
	FormParameters.Insert("AdditionalAttribute", Object.Ref);
	FormParameters.Insert("AttributesDependencies", Object.AdditionalAttributesDependencies);
	FormParameters.Insert("Set", CurrentPropertiesSet);
	FormParameters.Insert("PropertyToConfigure", PropertyToConfigure);
	
	OpenForm("ChartOfCharacteristicTypes.AdditionalAttributesAndInfo.Form.AttributesDependency", FormParameters);
	
EndProcedure

&AtServer
Procedure SetFormHeader()
	
	If ValueIsFilled(Object.Ref) Then
		If Object.PropertyKind1 = Enums.PropertiesKinds.AdditionalInfo
			Or Object.IsAdditionalInfo Then
			Title = String(Object.Title) + " " + NStr("vi = '(Thông tin bổ sung)';
														|ru = '(Дополнительное сведение)';
														|en = '(Additional information record)'; fa = '(Additional information record)';
														|it = '(Informazione aggiuntiva)';
														|pl = '(Dodatkowa informacja)';
														|tr = '(Ek bilgi)'");
		ElsIf Object.PropertyKind1 = Enums.PropertiesKinds.Labels Then
			Title = String(Object.Title) + " " + NStr("vi = '(Nhãn)';
														|ru = '(Метка)';
														|en = '(Label)'; fa = '(Label)';
														|it = '(Метка)';
														|pl = '(Label)';
														|tr = '(Etiket)'");
		Else
			Title = String(Object.Title) + " " + NStr("vi = '(Mục tin bổ sung)';
														|ru = '(Дополнительный реквизит)';
														|en = '(Additional attribute)'; fa = '(Additional attribute)';
														|it = '(Requisito aggiuntivo)';
														|pl = '(Atrybut dodatkowy)';
														|tr = '(Ek öznitelik)'");
		EndIf;
	Else
		If Object.PropertyKind1 = Enums.PropertiesKinds.AdditionalInfo
			Or Object.IsAdditionalInfo Then
			Title = NStr("vi = 'Thông tin bổ sung (tạo mới)';
						|ru = 'Дополнительное сведение (создание)';
						|en = 'Additional information record (Create)'; fa = 'Additional information record (Create)';
						|it = 'Informazione aggiuntiva (creazione)';
						|pl = 'Informacja dodatkowa (tworzenie)';
						|tr = 'Ek bilgi (oluştur)'");
		ElsIf Object.PropertyKind1 = Enums.PropertiesKinds.Labels Then
			Title = NStr("vi = 'Nhãn (tạo mới)';
						|ru = 'Метка (создание)';
						|en = 'Label (Create)'; fa = 'Label (Create)';
						|it = 'Метка (создание)';
						|pl = 'Label (Create)';
						|tr = 'Etiket (oluşturma)'");
		Else
			Title = NStr("vi = 'Mục tin bổ sung (tạo mới)';
						|ru = 'Дополнительный реквизит (создание)';
						|en = 'Additional attribute (Create)'; fa = 'Additional attribute (Create)';
						|it = 'Requisito aggiuntivo (creazione)';
						|pl = 'Atrybut dodatkowy (tworzenie)';
						|tr = 'Ek öznitelik (oluştur)'");
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnChangeCurrentSet()
	
	If Items.PropertiesSets.CurrentData = Undefined Then
		If ValueIsFilled(SelectedPropertiesSet) Then
			SelectedPropertiesSet = Undefined;
			OnChangeCurrentSetAtServer();
		EndIf;
		
	ElsIf Items.PropertiesSets.CurrentData.Ref <> SelectedPropertiesSet Then
		SelectedPropertiesSet = Items.PropertiesSets.CurrentData.Ref;
		CurrentSetIsFolder = Items.PropertiesSets.CurrentData.IsFolder;
		OnChangeCurrentSetAtServer(CurrentSetIsFolder);
	EndIf;
	
EndProcedure

&AtServer
Procedure OnChangeCurrentSetAtServer(CurrentSetIsFolder = Undefined)
	
	If ValueIsFilled(SelectedPropertiesSet)
		And Not CurrentSetIsFolder Then
		UpdateCurrentSetPropertiesList();
	Else
		Properties.Clear();
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateCurrentSetPropertiesList()
	
	PropertyManagerInternal.UpdateCurrentSetPropertiesList(ThisObject, 
			SelectedPropertiesSet,
			PropertyKind1);
	
EndProcedure

&AtServer
Procedure NewPassedParametersStructure()
	PassedFormParameters = New Structure;
	PassedFormParameters.Insert("AdditionalValuesOwner");
	PassedFormParameters.Insert("ShowSetAdjustment", True);
	PassedFormParameters.Insert("CurrentPropertiesSet");
	PassedFormParameters.Insert("PropertyKind1");
	PassedFormParameters.Insert("SelectSharedProperty");
	PassedFormParameters.Insert("SelectedValues");
	PassedFormParameters.Insert("SelectAdditionalValuesOwner");
	PassedFormParameters.Insert("CopyingValue");
	PassedFormParameters.Insert("CopyWithQuestion");
	PassedFormParameters.Insert("Drag", False);
	
	FillPropertyValues(PassedFormParameters, Parameters, , "ShowSetAdjustment");
	
	ValuesOwner = PassedFormParameters.AdditionalValuesOwner;
	If ValueIsFilled(ValuesOwner) Then
		ValuesOwner = Common.ObjectAttributeValue(ValuesOwner, "AdditionalValuesOwner");
		If ValueIsFilled(ValuesOwner) Then
			PassedFormParameters.AdditionalValuesOwner = ValuesOwner;
		EndIf;
	EndIf;
EndProcedure

&AtServerNoContext
Function DescriptionAlreadyUsed(Val Title, Val CurrentProperty, Val PropertiesSet, NewDescription, Val TitleLanguage1, Val TitleLanguage2)
	
	If Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
		ModuleNationalLanguageSupportServer = Common.CommonModule("NationalLanguageSupportServer");
		
		If ModuleNationalLanguageSupportServer.FirstAdditionalInfobaseLanguageCode() = CurrentLanguage().LanguageCode Then
			Title = TitleLanguage1;
		ElsIf ModuleNationalLanguageSupportServer.SecondAdditionalInfobaseLanguageCode() = CurrentLanguage().LanguageCode Then
			Title = TitleLanguage2;
		EndIf;
	
	EndIf;
	
	NewDescription = Title;
	
	Return PropertyManagerInternal.DescriptionAlreadyUsed(CurrentProperty, PropertiesSet, NewDescription);
	
EndFunction

&AtServerNoContext
Function NameAlreadyUsed(Val Name, Val CurrentProperty, NewDescription)
	
	Return PropertyManagerInternal.NameAlreadyUsed(Name, CurrentProperty);
	
EndFunction

&AtServerNoContext
Function IDForFormulasAlreadyUsed(Val IDForFormulas, Val CurrentProperty)
	
	QueryText = PropertyManagerInternal.IDForFormulasAlreadyUsed(IDForFormulas, CurrentProperty);
	If Not ValueIsFilled(QueryText) Then
		Return "";
	EndIf;
	
	Refinement = NStr("vi = 'Tạo tên định danh mới đối với công thức và tiếp tục ghi?';
						|ru = 'Создать новый идентификатор для формул и продолжить запись?';
						|en = 'Do you want to create a new ID for formulas and continue saving?'; fa = 'Do you want to create a new ID for formulas and continue saving?';
						|it = 'Создать новый идентификатор для формул и продолжить запись?';
						|pl = 'Do you want to create a new ID for formulas and continue saving?';
						|tr = 'Formül için yeni bir tanımlayıcı oluşturulsun ve kayıt devam edilsin mi?'");
	QueryText = QueryText + Chars.LF + Chars.LF + Refinement;
	Return QueryText;
	
EndFunction

&AtClientAtServerNoContext
Procedure SetFormatButtonTitle(Form)
	
	If IsBlankString(Form.Object.FormatProperties) Then
		TitleText = NStr("vi = 'Định dạng mặc định';
						|ru = 'Формат по умолчанию';
						|en = 'Default format'; fa = 'Default format';
						|it = 'Formato di default';
						|pl = 'Format domyślny';
						|tr = 'Varsayılan format'");
	Else
		TitleText = NStr("vi = 'Đã thiết lập định dạng';
						|ru = 'Формат установлен';
						|en = 'Custom format'; fa = 'Custom format';
						|it = 'Formato impostato';
						|pl = 'Format został ustawiony';
						|tr = 'Biçim ayarlandı'");
	EndIf;
	
	Form.Items.EditValueFormat.Title = TitleText;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetLabelColor(Form, ColorOfLabel)
	
	Items = Form.Items;
	Items.PropertyGray.Check = (ColorOfLabel = PredefinedValue("Enum.PropertiesColors.EmptyRef")
								Or ColorOfLabel = PredefinedValue("Enum.PropertiesColors.Gray"));
	Items.PropertyLightBlue.Check = (ColorOfLabel = PredefinedValue("Enum.PropertiesColors.LightBlue"));
	Items.PropertyYellow.Check = (ColorOfLabel = PredefinedValue("Enum.PropertiesColors.Yellow"));
	Items.PropertyGreen.Check = (ColorOfLabel = PredefinedValue("Enum.PropertiesColors.Green"));
	Items.PropertyLime.Check = (ColorOfLabel = PredefinedValue("Enum.PropertiesColors.GreenLime"));
	Items.PropertyRed.Check = (ColorOfLabel = PredefinedValue("Enum.PropertiesColors.Red"));
	Items.PropertyOrange.Check = (ColorOfLabel = PredefinedValue("Enum.PropertiesColors.Orange"));
	Items.PropertyPink.Check = (ColorOfLabel = PredefinedValue("Enum.PropertiesColors.Pink"));
	Items.PropertyBlue.Check = (ColorOfLabel = PredefinedValue("Enum.PropertiesColors.B"));
	Items.PropertyPurple.Check = (ColorOfLabel = PredefinedValue("Enum.PropertiesColors.Violet"));
	
EndProcedure

#EndRegion