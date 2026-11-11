//@strict-types

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	HasUpdateRight = AccessRight("Update", Metadata.Catalogs.VendorRebateKinds);
	
	If ExchangePlans.MasterNode() <> Undefined Then
		
		Items.List.ChangeRowSet = False;
		HasUpdateRight = False;
		
	EndIf;
	
	Items.GroupSetStatus.Visible = HasUpdateRight;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.ListCommandBar);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	SetConditionalAppearance();
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.List);
	
EndProcedure

// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Async Procedure SetStatusToPrepared(Command)
	
	TypesToProcessing = SelectedViewsToChangeStatus();
	If TypesToProcessing.Count() = 0 Then
		Return;
	EndIf;
	
	QueryText = NStr("vi = 'Sẽ đặt trạng thái ""Đã chuẩn bị"" cho các dạng thưởng lũy kế đã chọn trong danh sách.
						|Tiếp tục?';
						|ru = 'У выделенных в списке видов ретро-бонусов будет установлен статус ""Подготовлен"".
						|Продолжить?';
						|en = 'Status of the rebate kinds selected in the list will be set to ""Prepared"".
						|Continue?'; fa = 'Status of the rebate kinds selected in the list will be set to ""Prepared"".
						|Continue?';
						|it = 'У выделенных в списке видов ретро-бонусов будет установлен статус ""Подготовлен"".
						|Продолжить?';
						|pl = 'Status of the rebate kinds selected in the list will be set to ""Prepared"".
						|Continue?';
						|tr = 'Girilen retro bonusu türleri ""Hazırlandı"" durumuna ayarlanacak.
						|Devam edilsin mi?'");
	
	Response = Await DoQueryBoxAsync(QueryText, QuestionDialogMode.YesNo); // DialogReturnCode
	If Response = DialogReturnCode.Yes Then
		
		ClearMessages();
		
		ProcessedItemsCount = SetStatusServer(
			TypesToProcessing,
			PredefinedValue("Enum.RebatesKindsStatuses.Prepared"));
			
		NotifyUserAboutSettingStatus(
			Items.List,
			ProcessedItemsCount,
			TypesToProcessing.Count(),
			NStr("vi = 'Đã chuẩn bị';
				|ru = 'Подготовлен';
				|en = 'Prepared'; fa = 'آماده‌شده';
				|it = 'Подготовлен';
				|pl = 'Prepared';
				|tr = 'Hazırlandı'"));
		
	EndIf;
	
EndProcedure

&AtClient
Async Procedure SetStatusValid(Command)
	
	TypesToProcessing = SelectedViewsToChangeStatus();
	If TypesToProcessing.Count() = 0 Then
		Return;
	EndIf;
	
	QueryText = NStr("vi = 'Sẽ đặt trạng thái ""Có hiệu lực"" cho các dạng thưởng lũy kế đã chọn trong danh sách.
						|Tiếp tục?';
						|ru = 'У выделенных в списке видов ретро-бонусов будет установлен статус ""Действует"". 
						|Продолжить?';
						|en = 'Status of the rebate kinds selected in the list will be set to ""Valid"".
						|Continue?'; fa = 'Status of the rebate kinds selected in the list will be set to ""Valid"".
						|Continue?';
						|it = 'У выделенных в списке видов ретро-бонусов будет установлен статус ""Действует"". 
						|Продолжить?';
						|pl = 'Status of the rebate kinds selected in the list will be set to ""Valid"".
						|Continue?';
						|tr = 'Girilen retro bonusu türleri ""Aktif"" durumuna ayarlanacak.
						|Devam edilsin mi?'");
	Response = Await DoQueryBoxAsync(QueryText, QuestionDialogMode.YesNo); // DialogReturnCode
	If Response = DialogReturnCode.Yes Then
		
		ClearMessages();
		
		ProcessedItemsCount = SetStatusServer(
			TypesToProcessing,
			PredefinedValue("Enum.RebatesKindsStatuses.Valid"));
			
		NotifyUserAboutSettingStatus(
			Items.List,
			ProcessedItemsCount,
			TypesToProcessing.Count(),
			NStr("vi = 'Có hiệu lực';
				|ru = 'Действует';
				|en = 'Valid'; fa = 'معتبر';
				|it = 'Действует';
				|pl = 'Valid';
				|tr = 'Aktif'"));
		
	EndIf;
	
EndProcedure

&AtClient
Async Procedure SetTheClosedStatus(Command)
	
	TypesToProcessing = SelectedViewsToChangeStatus();
	If TypesToProcessing.Count() = 0 Then
		Return;
	EndIf;
	
	QueryText = NStr("vi = 'Sẽ đặt trạng thái ""Đã đóng"" cho các dạng thưởng lũy kế đã chọn trong danh sách.
						|Sau khi thay đổi trạng thái, các dạng thưởng lũy kế đang hoạt động sẽ không còn hiệu lực.
						|Tiếp tục?';
						|ru = 'У выделенных в списке видов ретро-бонусов будет установлен статус ""Закрыт"".
						|После изменения статуса действующие виды ретро-бонусов перестанут действовать.
						|Продолжить?';
						|en = 'Status of the rebate kinds selected in the list will be set to ""Closed"".
						|Once the status is changed, the rebate kinds will be no longer valid.
						|Continue?'; fa = 'Status of the rebate kinds selected in the list will be set to ""Closed"".
						|Once the status is changed, the rebate kinds will be no longer valid.
						|Continue?';
						|it = 'У выделенных в списке видов ретро-бонусов будет установлен статус ""Закрыт"".
						|После изменения статуса действующие виды ретро-бонусов перестанут действовать.
						|Продолжить?';
						|pl = 'Status of the rebate kinds selected in the list will be set to ""Closed"".
						|Once the status is changed, the rebate kinds will be no longer valid.
						|Continue?';
						|tr = 'Listede seçili retro bonusların durumu ""Kapalı"" olarak ayarlanacaktır.
						|Durum değiştirildikten sonra, mevcut retro bonusların geçerliliği sona erecektir.
						|Devam edilsin mi?'");
	
	Response = Await DoQueryBoxAsync(QueryText, QuestionDialogMode.YesNo); // DialogReturnCode
	If Response = DialogReturnCode.Yes Then
		
		ClearMessages();
		
		ProcessedItemsCount = SetStatusServer(
			TypesToProcessing,
			PredefinedValue("Enum.RebatesKindsStatuses.Closed"));
			
		NotifyUserAboutSettingStatus(
			Items.List,
			ProcessedItemsCount,
			TypesToProcessing.Count(),
			NStr("vi = 'Đã đóng';
				|ru = 'Закрыт';
				|en = 'Closed'; fa = 'بسته‌شده';
				|it = 'Закрыт';
				|pl = 'Closed';
				|tr = 'Kapalı'"));
		
	EndIf;
	
EndProcedure

// StandardSubsystems.AttachableCommands

// Parameters:
//   Command - FormCommand - executed command
//
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Items.List);
	
EndProcedure

// End StandardSubsystems.AttachableCommands

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	FieldsNames = New Array; // Array of String
	FieldsNames.Add(Items.BonusType.Name);
	FieldsNames.Add(Items.BaseOfCalculation.Name);
	FieldsNames.Add(Items.ConditionFrequency.Name);
	RebatesServer.SetConditionalAppearanceOfViewListWithoutCalculation(ThisObject, FieldsNames);
	
	FieldsNames = New Array; // Array of String
	FieldsNames.Add(Items.ConditionFrequency.Name);
	RebatesServer.SetConditionalAppearanceOfListOfTypeIndicatorOfGoodsNotUsed(ThisObject, FieldsNames);
	
	#Region BaseOfCalculation_TimeFenceOfAccruals
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.BaseOfCalculation.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AccrualFrequency.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.BonusType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.VendorRebateTypes.Balance;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	#EndRegion
	
EndProcedure

&AtServerNoContext
Function SetStatusServer(Val RebateKinds, Val NewStatus)
	
	Return Catalogs.VendorRebateKinds.SetStatus(
		RebateKinds,
		NewStatus);
	
EndFunction

// The procedure shows an alert after processing the Statuses highlighted in the list of species
//
// Parameters:
//	ListOfSpecies  - FormTable - Form element
//	ProcessedItemsCount - Number - number of successfully processed species
//	TotalCount1 - Number - the number of species highlighted in the list
//	Status - String - set the status.
//
&AtClient
Procedure NotifyUserAboutSettingStatus(ListOfSpecies, ProcessedItemsCount, TotalCount1, Status)
	
	If ProcessedItemsCount > 0 Then
		
		If ListOfSpecies <> Undefined Then
			ListOfSpecies.Refresh();
		EndIf;
		
		MessageText = NStr("vi = 'Đối với %ProcessedItemsCount% trong số %TotalCount1% đối tượng được chọn trong danh sách đã đặt trạng thái ""%Status%""';
							|ru = 'Для %ProcessedItemsCount% из %TotalCount1% выделенных в списке объектов установлен статус ""%Status%""';
							|en = 'The ""%Status%"" status is set for %ProcessedItemsCount% out of %TotalCount1% objects selected in the list'; fa = 'The ""%Status%"" status is set for %ProcessedItemsCount% out of %TotalCount1% objects selected in the list';
							|it = 'Для %ProcessedItemsCount% из %TotalCount1% выделенных в списке объектов установлен статус ""%Status%""';
							|pl = 'The ""%Status%"" status is set for %ProcessedItemsCount% out of %TotalCount1% objects selected in the list';
							|tr = 'Belgeler listesinde seçilen %TotalCount1% üzerinden %ProcessedItemsCount% için durum ""%Status%"" olarak ayarlanır'");
		MessageText = StrReplace(MessageText, "%ProcessedItemsCount%", String(ProcessedItemsCount));
		MessageText = StrReplace(MessageText, "%TotalCount1%", String(TotalCount1));
		MessageText = StrReplace(MessageText, "%Status%", Status);
		TitleText = NStr("vi = 'Trạng thái ""%Status%"" đã đặt';
						|ru = 'Статус ""%Status%"" установлен';
						|en = 'Status ""%Status%"" is set'; fa = 'Status ""%Status%"" is set';
						|it = 'Статус ""%Status%"" установлен';
						|pl = 'Ustawiono status ""%Status%""';
						|tr = 'Durum ""%Status%"" ayarlandı'");
		TitleText = StrReplace(TitleText, "%Status%", Status);
		ShowUserNotification(TitleText,, MessageText, PictureLib.Information32);
		
	Else
		
		MessageText = NStr("vi = 'Trạng thái ""%Status%"" chưa được đặt cho một đối tượng nào';
							|ru = 'Статус ""%Status%"" не установлен ни для одного объекта';
							|en = 'The ""%Status%"" status is not set for any object'; fa = 'The ""%Status%"" status is not set for any object';
							|it = 'Статус ""%Status%"" не установлен ни для одного объекта';
							|pl = 'The ""%Status%"" status is not set for any object';
							|tr = '""%Status%"" durumu herhangi bir nesne için ayarlanmadı'");
		MessageText = StrReplace(MessageText, "%Status%", Status);
		TitleText = NStr("vi = 'Trạng thái ""%Status%"" chưa đặt';
						|ru = 'Статус ""%Status%"" не установлен';
						|en = 'Status ""%Status%"" is not set'; fa = 'Status ""%Status%"" is not set';
						|it = 'Статус ""%Status%"" не установлен';
						|pl = 'Nie ustawiono statusu ""%Status%""';
						|tr = 'Durum ""%Status%"" ayarlanmadı'");
		TitleText = StrReplace(TitleText, "%Status%", Status);
		ShowUserNotification(TitleText,, MessageText, PictureLib.Information32);
		
	EndIf;
	
EndProcedure

// Returns:
//  Array of CatalogRef.VendorRebateKinds
//
&AtClient
Function SelectedViewsToChangeStatus()
	
	TypesToProcessing = New Array; // Array of CatalogRef.VendorRebateKinds
	
	SelectedRows = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.List);
	If SelectedRows.Count() = 0 Then
		
		Return TypesToProcessing;
		
	EndIf;
	
	SelectedTypesOfGroups = New Array; // Array of CatalogRef.VendorRebateKinds
	For Each RebateKind In Items.List.SelectedRows Do // CatalogRef.VendorRebateKinds
		
		RowData = Items.List.RowData(RebateKind);
		If RowData.IsFolder Then
			
			SelectedTypesOfGroups.Add(RebateKind);
			
		EndIf;
		
	EndDo;
	
	TypesToProcessing = CommonClientServer.ArraysDifference(SelectedRows, SelectedTypesOfGroups);
	Return TypesToProcessing;
	
EndFunction

#Region StandardSubsystems_PlugInCommands

// StandardSubsystems.AttachableCommands

// The Attachable one continues to execute the Commands on the server.
// 
// Parameters:
//  ExecutionParameters - Structure -
//  AdditionalParameters - Structure -
//
&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	
	ExecuteCommandAtServer(ExecutionParameters);
	
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Items.List);
	
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
	
EndProcedure

// End StandardSubsystems.AttachableCommands

#EndRegion

#EndRegion	