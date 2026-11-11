///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If TypeOf(Parameters.LockedAttributes) = Type("Array") Then
		LockedAttributes = New FixedArray(Parameters.LockedAttributes);
		
	ElsIf ValueIsFilled(Parameters.FullObjectName) Then
		LockedAttributes = New FixedArray(
			ObjectAttributesLock.ObjectAttributesToLock(
				Parameters.FullObjectName));
	Else
		LockedAttributes = New FixedArray(New Array);
	EndIf;
	
	ItemsToAdd1 = New Array; // Array of See FormElementNewProperties
	AddBankingDetailsToForm(ItemsToAdd1);
	AddElementsToForm(ItemsToAdd1);
	
	If Parameters.BatchEditObjects Then
		If IsTempStorageURL(Parameters.AddressOfRefsToObjects) Then
			AddressOfRefsToObjects = Parameters.AddressOfRefsToObjects;
		EndIf;
	ElsIf ValueIsFilled(Parameters.Ref) Then
		AddressOfRefsToObjects = PutToTempStorage(
			CommonClientServer.ValueInArray(Parameters.Ref),
			UUID);
	EndIf;
	
	If Not ValueIsFilled(AddressOfRefsToObjects) Then
		Items.FormCheckIfUsed.Visible = False;
	EndIf;
	
	StandardSubsystemsServer.ResetWindowLocationAndSize(ThisObject);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	EditCheckboxes(True, ValueIsFilled(MarkedAttribute));
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CheckAll(Command)
	
	EditCheckboxes(True);
	
EndProcedure

&AtClient
Procedure UncheckAll(Command)
	
	EditCheckboxes(False);
	
EndProcedure

&AtClient
Procedure Validate(Command)
	
	If CommonClient.SubsystemExists("StandardSubsystems.DuplicateObjectsDetection") Then
		OpeningParameters = New Structure;
		OpeningParameters.Insert("Uniqueness", UUID);
		ReferencesArrray = GetFromTempStorage(AddressOfRefsToObjects);
		ModuleDuplicateObjectsDetectionClient = CommonClient.CommonModule("DuplicateObjectsDetectionClient");
		ModuleDuplicateObjectsDetectionClient.ShowUsageInstances(ReferencesArrray, OpeningParameters);
		Return;
	EndIf;
	
	Items.Pages.CurrentPage = Items.TimeConsumingOperation;
	
	TimeConsumingOperation = AreObjectsUsed();
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	IdleParameters.OutputIdleWindow = False;
	
	CallbackOnCompletion = New CallbackDescription("ValidateCompletion", ThisObject);
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
	
EndProcedure

&AtClient
Procedure EnableEdit(Command)
	
	Result = New Array;
	
	For Each AddedAttribute In AttributesToUnlock Do
		If Not ThisObject[AddedAttribute.Key] Then
			Continue;
		EndIf;
		For Each AttributeName In AddedAttribute.Value Do
			Result.Add(AttributeName);
		EndDo;
	EndDo;
	
	If Not ValueIsFilled(Result) Then
		ShowMessageBox(, NStr("vi = 'Vui lòng chọn ít nhất một mục tin';
								|ru = 'Выберите хотя бы один реквизит';
								|en = 'Please select at least one attribute.'; fa = 'Please select at least one attribute.';
								|it = 'Выберите хотя бы один реквизит';
								|pl = 'Please select at least one attribute.';
								|tr = 'En az bir öznitelik seçin'"));
		Return;
	EndIf;
	
	Close(Result);
	
EndProcedure

#EndRegion

#Region Private

// Returns:
//  Structure:
//   * IsLabel     - Boolean
//   * Name            - String
//   * Title      - String
//   * Warning - String
//
&AtServerNoContext
Function FormElementNewProperties()
	
	NewProperties = New Structure;
	NewProperties.Insert("IsLabel", False);
	NewProperties.Insert("Name", "");
	NewProperties.Insert("Title", "");
	NewProperties.Insert("Warning", "");
	
	Return NewProperties;
	
EndFunction

&AtServer
Procedure AddBankingDetailsToForm(ItemsToAdd1)
	
	If ValueIsFilled(Parameters.FullObjectName) Then
		AttributesToLock = New FixedArray(
			ObjectAttributesLockInternal.BlockedObjectDetailsAndFormElements(
				Parameters.FullObjectName));
	Else
		AttributesToLock = New FixedArray(New Array);
	EndIf;
	
	LongDesc = New ValueTable;
	LongDesc.Columns.Add("AttributeName",            New TypeDescription("String"));
	LongDesc.Columns.Add("Presentation",           New TypeDescription("String"));
	LongDesc.Columns.Add("EditingAllowed", New TypeDescription("Boolean"));
	LongDesc.Columns.Add("ItemsToLock",     New TypeDescription("Array"));
	LongDesc.Columns.Add("RightToEdit",     New TypeDescription("Boolean"));
	
	If TypeOf(Parameters.DetailsOfAttributesToLock) = Type("Array") Then
		For Each AttributeDetails In Parameters.DetailsOfAttributesToLock Do
			FillPropertyValues(LongDesc.Add(), AttributeDetails);
		EndDo;
	Else
		ObjectMetadata = Common.MetadataObjectByFullName(Parameters.FullObjectName);
		ObjectAttributesLockInternal.PopulateDetailsForLockedAttributes(LongDesc,
			ObjectMetadata, AttributesToLock, False);
	EndIf;
	
	AttributesToBeAdded = New Array;
	AddedAttributes = New Map;
	GroupsProperties = New Map;
	IsCommonLabelSetUp = False;
	For Each AttributeToLock In AttributesToLock Do
		If ValueIsFilled(AttributeToLock.Group)
		 Or ValueIsFilled(AttributeToLock.GroupPresentation) Then
			GroupProperties = GroupsProperties.Get(AttributeToLock.Group);
			If GroupProperties = Undefined Then
				GroupProperties = New Structure;
				GroupProperties.Insert("Presentation", AttributeToLock.GroupPresentation);
				GroupProperties.Insert("Warning", AttributeToLock.Warning);
				GroupProperties.Insert("WarningForGroup", AttributeToLock.WarningForGroup);
				GroupsProperties.Insert(AttributeToLock.Group, GroupProperties);
			EndIf;
		EndIf;
		If Not IsCommonLabelSetUp Then
			IsCommonLabelSetUp = True;
			If Not ValueIsFilled(AttributeToLock.Name)
			   And AttributeToLock.Group = "CommonLabel" Then
				If Not ValueIsFilled(AttributeToLock.GroupPresentation) Then
					Continue;
				EndIf;
				LabelTitle = AttributeToLock.GroupPresentation;
			Else
				LabelTitle =
					NStr("vi = 'Trước khi thay đổi mục tin, cần kiểm tra việc sử dụng đối tượng.
					           |Nếu đối tượng được sử dụng thì cần đánh giá hậu quả thay đổi.';
					           |ru = 'Перед изменением реквизитов рекомендуется проверить использование объекта.
					           |Если объект используется, то необходимо оценить последствия изменений.';
					           |en = 'Check if the object is in use before changing the attributes.
					           |If the object is in use, assess the effects of changes.'; fa = 'پیش از تغییر ویژگی‌ها بررسی کنید که آیا شیء در حال استفاده است.
					           |اگر شیء در حال استفاده باشد، اثرات تغییرات را ارزیابی کنید.';
					           |it = 'Prima di modificare i requisiti si consiglia di verificare l''utilizzo dell''oggetto. 
					           | Se l''oggetto è in uso, bisogna valutare le conseguenze delle modifiche.';
					           |pl = 'Przed zmianą atrybutów zalecane jest sprawdzenie korzystania z obiektu.
					           |Jeśli obiekt jest używany, wtedy należy ocenić konsekwencje zmian.';
					           |tr = 'Öznitelikleri değiştirmeden önce nesnenin kullanımını kontrol etmeniz tavsiye edilir.
					           | Nesne kullanımdaysa, değişikliklerin etkilerinin değerlendirilmesi gerekir.'");
			EndIf;
			ItemProperties = FormElementNewProperties();
			ItemProperties.IsLabel = True;
			ItemProperties.Name = "CommonLabel";
			ItemProperties.Title = LabelTitle;
			ItemsToAdd1.Add(ItemProperties);
		EndIf;
		If LockedAttributes.Find(AttributeToLock.Name) = Undefined Then
			Continue;
		EndIf;
		AttributeDetails = LongDesc.Find(AttributeToLock.Name, "AttributeName");
		If AttributeDetails = Undefined
		 Or Not AttributeDetails.RightToEdit Then
			Continue;
		EndIf;
		GroupProperties = GroupsProperties.Get(AttributeToLock.Group);
		If GroupProperties <> Undefined Then
			If Parameters.BatchEditObjects Then
				FullAttributeName = "AttributeToUnlock" + AttributeToLock.Name;
				AttributeRepresentation = AttributeDetails.Presentation;
				If ValueIsFilled(AttributeToLock.Warning) Then
					WarningForAttribute = AttributeToLock.Warning;
				Else
					WarningForAttribute = GroupProperties.Warning;
				EndIf;
			Else
				FullAttributeName = "AttributeToUnlock" + AttributeToLock.Group;
				AttributeRepresentation  = GroupProperties.Presentation;
				If ValueIsFilled(GroupProperties.WarningForGroup) Then
					WarningForAttribute = GroupProperties.WarningForGroup;
				Else
					WarningForAttribute = GroupProperties.Warning;
				EndIf;
			EndIf;
		Else
			FullAttributeName = "AttributeToUnlock" + AttributeToLock.Name;
			AttributeRepresentation = AttributeDetails.Presentation;
			WarningForAttribute = AttributeToLock.Warning;
		EndIf;
		Added1 = AddedAttributes.Get(FullAttributeName);
		If Added1 = Undefined Then
			If AttributeToLock.Name = Parameters.MarkedAttribute Then
				MarkedAttribute = FullAttributeName;
			EndIf;
			Added1 = New Array;
			AddedAttributes.Insert(FullAttributeName, Added1);
			AttributesToBeAdded.Add(New FormAttribute(FullAttributeName,
				New TypeDescription("Boolean"),, AttributeRepresentation));
			ItemProperties = FormElementNewProperties();
			ItemProperties.IsLabel = False;
			ItemProperties.Name = FullAttributeName;
			ItemProperties.Warning = WarningForAttribute;
			ItemsToAdd1.Add(ItemProperties);
		EndIf;
		Added1.Add(AttributeToLock.Name);
	EndDo;
	ChangeAttributes(AttributesToBeAdded);
	
	AttributesToUnlock = Common.FixedData(AddedAttributes);
	
EndProcedure

&AtServer
Procedure AddElementsToForm(ItemsToAdd1)
	
	ParentElement = Items.Main_Page;
	CheckBoxItem = Undefined;
	
	For Each ItemToAdd In ItemsToAdd1 Do
		If ItemToAdd.IsLabel Then
			LabelItem = Items.Add(ItemToAdd.Name,
				Type("FormDecoration"), ParentElement);
			LabelItem.Type = FormDecorationType.Label;
			LabelItem.Title = ItemToAdd.Title;
			LabelItem.TextColor = Metadata.StyleItems.OverdueDataColor.Value;
			LabelItem.AutoMaxWidth = False;
		Else
			HasIndent = CheckBoxItem <> Undefined
				And ValueIsFilled(CheckBoxItem.ExtendedTooltip.Title);
			If HasIndent Then
				FlagGroup = Items.Add("Group" + ItemToAdd.Name,
					Type("FormGroup"), ParentElement);
				FlagGroup.Type = FormGroupType.UsualGroup;
				FlagGroup.ShowTitle = False;
				FlagGroup.Representation = UsualGroupRepresentation.NormalSeparation;
			Else
				FlagGroup = ParentElement;
			EndIf;
			CheckBoxItem = Items.Add(ItemToAdd.Name,
				Type("FormField"), FlagGroup);
			CheckBoxItem.Type = FormFieldType.CheckBoxField;
			CheckBoxItem.TitleLocation = FormItemTitleLocation.Right;
			CheckBoxItem.DataPath = ItemToAdd.Name;
			If ValueIsFilled(ItemToAdd.Warning) Then
				CheckBoxItem.ToolTipRepresentation = ToolTipRepresentation.ShowTop;
				CheckBoxItem.ExtendedTooltip.Title = ItemToAdd.Warning;
				CheckBoxItem.ExtendedTooltip.AutoMaxWidth = False;
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Procedure EditCheckboxes(Value, OnlyIfMarked = False)
	
	For Each CurrentAttributeBeingUnlocked In AttributesToUnlock Do
		If Not OnlyIfMarked
		 Or CurrentAttributeBeingUnlocked.Key = MarkedAttribute Then
			ThisObject[CurrentAttributeBeingUnlocked.Key] = Value;
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Function AreObjectsUsed()
	
	References = GetFromTempStorage(AddressOfRefsToObjects);
	RefsCount = References.Count();
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Dỡ bỏ phong tỏa mục tin: Kiểm tra sử dụng tham chiếu đến đối tượng';
														|ru = 'Разблокирование реквизитов: Проверка использования ссылок на объекты';
														|en = 'Unlock attributes: Check the object reference usage'; fa = 'Unlock attributes: Check the object reference usage';
														|it = 'Разблокирование реквизитов: Проверка использования ссылок на объекты';
														|pl = 'Unlock attributes: Check the object reference usage';
														|tr = 'Özniteliklerin kilidinin açılması: Nesnelerde bağlantı kullanımının kontrolü'");
	// In file mode, the job queue always runs in the background. The result is of low priority, the operation runs rarely.
	// Therefore, locking the UI is excessive as the search for object references takes a long time.
	ExecutionParameters.RunInBackground = True;
	ExecutionParameters.WaitCompletion = 0;
	
	Return TimeConsumingOperations.ExecuteFunction(ExecutionParameters,
		"Common.RefsToObjectFound", References);
	
EndFunction

// Parameters:
//  Result - See TimeConsumingOperationsClient.NewResultLongOperation
//  AdditionalParameters - Undefined
//
&AtClient
Procedure ValidateCompletion(Result, AdditionalParameters) Export
	
	Items.Pages.CurrentPage = Items.Main_Page;
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		StandardSubsystemsClient.OutputErrorInfo(
			Result.ErrorInfo);
		Return;
	EndIf;
	
	AreObjectsUsed = GetFromTempStorage(Result.ResultAddress);
	If TypeOf(AreObjectsUsed) <> Type("Boolean") Then
		ShowMessageBox(, NStr("vi = 'Không thể nhận kết quả kiểm tra, hãy thử lần nữa';
								|ru = 'Не удалось получить результат проверки, попробуйте еще раз';
								|en = 'Cannot receive the check result. Please try again'; fa = 'Cannot receive the check result. Please try again';
								|it = 'Не удалось получить результат проверки, попробуйте еще раз';
								|pl = 'Cannot receive the check result. Please try again';
								|tr = 'Kontrol sonucu alınamadı, bir kez daha deneyin'"));
		Return;
	EndIf;
	
	If AreObjectsUsed Then
		If RefsCount = 1 Then
			MessageText =
				NStr("vi = 'Đã sử dụng đối tượng ở nơi khác trong ứng dụng.
				           |Không nên cho phép soạn do rủi ro mâu thuẫn dữ liệu.';
				           |ru = 'Объект уже используется в других местах в приложении.
				           |Не рекомендуется разрешать редактирование из-за риска рассогласования данных.';
				           |en = 'The object is used elsewhere in the app.
				           |Editing this object might lead to data inconsistency.'; fa = 'The object is used elsewhere in the app.
				           |Editing this object might lead to data inconsistency.';
				           |it = 'Объект уже используется в других местах в приложении.
				           |Не рекомендуется разрешать редактирование из-за риска рассогласования данных.';
				           |pl = 'The object is used elsewhere in the app.
				           |Editing this object might lead to data inconsistency.';
				           |tr = 'Nesne zaten uygulamanın başka bir yerinde kullanılıyor.
				           |Veri tutarsızlığı riski nedeniyle düzenlemeye izin verilmesi önerilmez.'");
		Else
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đối tượng đã chọn (%1) đã được sử dụng ở nơi khác trong ứng dụng. 
				           |Không nên cho phép chỉnh sửa do rủi ro mâu thuẫn dữ liệu.';
				           |ru = 'Выбранные объекты (%1) уже используются в других местах в приложении.
				           |Не рекомендуется разрешать редактирование из-за риска рассогласования данных.';
				           |en = '%1 selected objects are used elsewhere in the app.
				           |Editing these objects might lead to data inconsistency.'; fa = '%1 selected objects are used elsewhere in the app.
				           |Editing these objects might lead to data inconsistency.';
				           |it = 'Выбранные объекты (%1) уже используются в других местах в приложении.
				           |Не рекомендуется разрешать редактирование из-за риска рассогласования данных.';
				           |pl = '%1 selected objects are used elsewhere in the app.
				           |Editing these objects might lead to data inconsistency.';
				           |tr = 'Seçilmiş nesneler (%1), uygulamadaki diğer yerlerde zaten kullanılıyor. 
				           |Veri yanlış hizalama riskinden dolayı düzenlemeye izin verilmemesi önerilir.'"),
				RefsCount);
		EndIf;
	Else
		If RefsCount = 1 Then
			MessageText =
				NStr("vi = 'Đối tượng còn chưa được sử dụng ở nơi khác trong ứng dụng.
				           | Có thể cho phép soạn mà không có rủi ro mâu thuẫn dữ liệu.';
				           |ru = 'Объект еще не используется в других местах в приложении.
				           |Можно разрешать редактирование без риска рассогласования данных.';
				           |en = 'The object is not used in other places in the app.
				           |You can allow editing it without the risk of data inconsistency.'; fa = 'The object is not used in other places in the app.
				           |You can allow editing it without the risk of data inconsistency.';
				           |it = 'Объект еще не используется в других местах в приложении.
				           |Можно разрешать редактирование без риска рассогласования данных.';
				           |pl = 'The object is not used in other places in the app.
				           |You can allow editing it without the risk of data inconsistency.';
				           |tr = 'Nesne, uygulamadaki diğer yerlerde henüz kullanılmıyor. 
				           |Veri yanlış hizalama riski olmadan düzenlemeye izin verilebilir.'");
		Else
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đối tượng đã chọn (%1) đã được sử dụng ở nơi khác trong ứng dụng. 
				           |Có thể cho phép soạn mà không có rủi ro mâu thuẫn dữ liệu.';
				           |ru = 'Выбранные объекты (%1) уже используются в других местах в приложении.
				           |Можно разрешать редактирование без риска рассогласования данных.';
				           |en = 'The selected objects (%1) are used in other places in the app.
				           |You can allow editing them without the risk of data inconsistency.'; fa = 'The selected objects (%1) are used in other places in the app.
				           |You can allow editing them without the risk of data inconsistency.';
				           |it = 'Выбранные объекты (%1) уже используются в других местах в приложении.
				           |Можно разрешать редактирование без риска рассогласования данных.';
				           |pl = 'The selected objects (%1) are used in other places in the app.
				           |You can allow editing them without the risk of data inconsistency.';
				           |tr = 'Seçilmiş nesneler (%1), uygulamadaki diğer yerlerde zaten kullanılıyor. 
				           |Veri yanlış hizalama riski olmadan düzenlemeye izin verilebilir.'"),
				RefsCount);
		EndIf;
	EndIf;
	
	ShowMessageBox(, MessageText);
	
EndProcedure

#EndRegion
