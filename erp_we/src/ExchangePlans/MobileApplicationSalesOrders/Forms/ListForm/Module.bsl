#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	Title = NStr("vi = 'Danh sách thiết bị di động có cài đặt ứng dụng di động ""1C:Đơn hàng""';
				|ru = 'Мобильные устройства с установленным мобильным приложением ""1С:Заказы""';
				|en = 'Mobile devices with installed 1C:Orders mobile application'; fa = 'Mobile devices with installed 1C:Orders mobile application';
				|it = 'Dispositivi mobili con applicazione mobile installata ""1C:Orders""';
				|pl = 'Urządzenia mobilne z zainstalowaną aplikacją mobilną ""1C:Orders"".';
				|tr = '""1C:Orders"" mobil uygulamasının yüklü olduğu mobil cihazlar'");
	
	SetDynamicListParameters();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
EndProcedure

#EndRegion

#Region FormHeaderEventHandlers

&AtClient
Procedure UserFilterOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(
		List, "User", User,
		DataCompositionComparisonType.Equal,, ValueIsFilled(User));
EndProcedure

#EndRegion

#Region ListFormTableEventHandlers

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	If TypeOf(RowSelected) = Type("DynamicListGroupRow") Then
		If Not TypeOf(RowSelected.Key) = Type("String") Then
			ShowValue(, RowSelected.Key);
		EndIf;
	Else
		ShowValue(, RowSelected);
	EndIf;
EndProcedure

&AtClient
Procedure ListOnActivateRow(Item)
	
	ListWhenActivatingLineOnClient(Items.List.CurrentData);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure MarkToDelete(Command)
	
	CurrentRow = Items.List.CurrentRow;
	CurrentData = Items.List.CurrentData;
	DeleteTagParameters = New Structure;
	If TypeOf(CurrentRow) = Type("DynamicListGroupRow") Then
		MarkForDeletion_ = ListItemMarkedForDeletion(CurrentRow.Key);
		If Not MarkForDeletion_ Then
			QueryText = NStr("vi = 'Nếu đặt dấu xóa tùy chỉnh đồng bộ,
			|thì trên thiết bị di động sẽ xóa tất cả dữ liệu của ứng dụng 1C:Đơn hàng vào phiên trao đổi tiếp theo.
			|Đặt dấu xóa tất cả tùy chỉnh khỏi nhóm ""%SettingsGroup%""?';
			|ru = 'Если пометить на удаление настройку синхронизации,
			|то на мобильном устройстве будут удалены все данные приложения 1С:Заказы при следующем сеансе обмена.
			|Пометить на удаление все настройки из группы ""%SettingsGroup%""?';
			|en = 'If you mark synchronization settings for deletion,
			|all data of application 1C:Orders will be deleted on mobile device during the next data exchange session.
			|Mark all settings from group ""%SettingsGroup%"" for deletion?'; fa = 'If you mark synchronization settings for deletion,
			|all data of application 1C:Orders will be deleted on mobile device during the next data exchange session.
			|Mark all settings from group ""%SettingsGroup%"" for deletion?';
			|it = 'Se si contrassegna un''impostazione di sincronizzazione per l''eliminazione,
			| tutti i dati verranno eliminati dal programma 1C:Orders durante la successiva sessione di scambio. 
			|Contrassegnare tutte le impostazioni dal gruppo ""%SettingsGroup%"" per l''eliminazione?';
			|pl = 'Jeśli zaznaczysz do usunięcia ustawienie synchronizacji,
			|wtedy na urządzeniu mobilnym podczas następnej sesji wymiany wszystkie dane z aplikacji 1C:Orders zostaną usunięte.
			|Chcesz zaznaczyć do usunięcia wszystkie ustawienia z grupy ""%SettingsGroup%""?';
			|tr = 'Senkronizasyon ayarını silinmek üzere işaretlerseniz,
			| mobil cihaz bir sonraki değişim oturumunda tüm 1C:Orders uygulama verilerini silecektir.
			| ""%SettingsGroup%"" grubundaki tüm ayarlar silinmek üzere işaretlensin mi?'");
		Else
			QueryText = NStr("vi = 'Bỏ dấu xóa tất cả tùy chỉnh khỏi nhóm ""%SettingsGroup%""?';
							|ru = 'Снять пометку на удаление со всех настроек из группы ""%SettingsGroup%""?';
							|en = 'Unmark for deletion all settings of group ""%SettingsGroup%""?'; fa = 'Unmark for deletion all settings of group ""%SettingsGroup%""?';
							|it = 'Deselezionare le impostazioni dal gruppo ""%SettingsGroup%"" per l''eliminazione?';
							|pl = 'Chcesz usunąć zaznaczenie do usunięcia ze wszystkich ustawień z grupy ""%SettingsGroup%""?';
							|tr = '""%SettingsGroup%"" grubundan tüm ayarları silme işareti kaldırılsın mı?'");
		EndIf;
		QueryText = StrReplace(QueryText, "%SettingsGroup%", CurrentRow.Key);
		DeleteTagParameters.Insert("ExchangeNode", CurrentRow.Key);
		DeleteTagParameters.Insert("IsFolder", True);
		DeleteTagParameters.Insert("DeletionMark", MarkForDeletion_);
	ElsIf TypeOf(CurrentRow) = Type("ExchangePlanRef.MobileApplicationSalesOrders") Then
		If CurrentData.DeletionMark Then
			QueryText = NStr("vi = 'Bỏ dấu xóa tùy chỉnh ""%Setting%""?';
							|ru = 'Снять пометку на удаление с настройки ""%Setting%""?';
							|en = 'Unmark setting ""%Setting%"" for deletion?'; fa = 'Unmark setting ""%Setting%"" for deletion?';
							|it = 'Deselezionare l''impostazione %Setting% per l''eliminazione?';
							|pl = 'Chcesz usunąć zaznaczenie do usunięcia z ustawienia ""%Setting%""?';
							|tr = '""%Setting%"" ayarını silme işareti kaldırılsın mı?'");
		Else
			QueryText = NStr("vi = 'Nếu đặt dấu xóa tùy chỉnh đồng bộ,
			|thì trên thiết bị di động sẽ xóa tất cả dữ liệu của ứng dụng 1C:Đơn hàng vào phiên trao đổi tiếp theo.
			|Đặt dấu xóa tùy chỉnh ""%Setting%""?';
			|ru = 'Если пометить на удаление настройку синхронизации,
			|то на мобильном устройстве будут удалены все данные приложения 1С:Заказы при следующем сеансе обмена.
			|Пометить на удаление настройку ""%Setting%""?';
			|en = 'If you mark synchronization setting for deletion,
			|all data of application 1C:Orders will be deleted on mobile device during the next data exchange session.
			|Mark setting ""%Setting%"" for deletion?'; fa = 'If you mark synchronization setting for deletion,
			|all data of application 1C:Orders will be deleted on mobile device during the next data exchange session.
			|Mark setting ""%Setting%"" for deletion?';
			|it = 'Se si contrassegna un''impostazione di sincronizzazione per l''eliminazione,
			| tutti i dati dal programma 1C:Orders verranno eliminati sul dispositivo mobile durante la sessione di scambio successiva. 
			|Contrassegnare l''impostazione ""%Setting%"" per l''eliminazione?';
			|pl = 'Jeśli zaznaczysz do usunięcia ustawienie synchronizacji,
			|wtedy na urządzeniu mobilnym podczas następnej sesji wymiany wszystkie dane z aplikacji 1C:Orders zostaną usunięte.
			|Chcesz zaznaczyć do usunięcia ustawienie ""%Setting%""?';
			|tr = 'Senkronizasyon ayarını silinmek üzere işaretlerseniz,
			| mobil cihaz bir sonraki değişim oturumunda tüm 1C:Orders uygulama verilerini silecektir.
			| ""%Setting%"" ayarı silinmek üzere işaretlensin mi?'");
		EndIf;
		QueryText = StrReplace(QueryText, "%Setting%", CurrentRow);
		DeleteTagParameters.Insert("ExchangeNode", CurrentRow);
		DeleteTagParameters.Insert("DeletionMark", CurrentData.DeletionMark);
	EndIf;
	QuestionTitle = NStr("vi = 'Tùy chỉnh đồng bộ';
						|ru = 'Настройки синхронизации';
						|en = 'Synchronization settings'; fa = 'تنظیمات همگام‌سازی';
						|it = 'Impostazioni di sincronizzazione';
						|pl = 'Ustawienia synchronizacji';
						|tr = 'Senkronizasyon ayarları'");
	CallbackDescription = New CallbackDescription("AfterAnsweringQuestionMarkDelete", ThisForm, DeleteTagParameters);
	ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo,, DialogReturnCode.No, QuestionTitle);
EndProcedure

&AtClient
Procedure CreateSetting(Command)
	
	CurrentRow = Items.List.CurrentRow;
	FormParameters = New Structure;
	If TypeOf(CurrentRow) = Type("DynamicListGroupRow") Then
		If Not TypeOf(CurrentRow.Key) = Type("String") And ValueIsFilled(CurrentRow.Key) Then
			FormParameters.Insert("KindExchangeSettings", CurrentRow.Key);
		EndIf;
	EndIf;
	If ValueIsFilled(User) Then
		FormParameters.Insert("User", User);
	EndIf;
	OpenForm("ExchangePlan.MobileApplicationSalesOrders.ObjectForm", FormParameters, ThisForm);
EndProcedure

&AtClient
Procedure CreateContextSetting(Command)
	
	CurrentRow = Items.List.CurrentRow;
	FormParameters = New Structure;
	If TypeOf(CurrentRow) = Type("DynamicListGroupRow") Then
		If TypeOf(CurrentRow.Key) = Type("String") Then
			If ValueIsFilled(User) Then
				FormParameters.Insert("User", User);
			EndIf;
		Else
			CopyExchangeNode(CurrentRow.Key, FormParameters);
		EndIf;
	ElsIf TypeOf(CurrentRow) = Type("ExchangePlanRef.MobileApplicationSalesOrders") Then
		CopyExchangeNode(CurrentRow, FormParameters);
	EndIf;
	OpenForm("ExchangePlan.MobileApplicationSalesOrders.ObjectForm", FormParameters, ThisForm);
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure MarkSettingsForDeletion(ExchangeNode, DeletionMark)
	
	MarkSettingForDeletion(ExchangeNode, DeletionMark);
	
	GroupSettings = ExchangePlans.MobileApplicationSalesOrders.Select(New Structure("KindExchangeSettings", ExchangeNode));
	While GroupSettings.Next() Do
		MarkSettingForDeletion(GroupSettings.Ref, DeletionMark);
	EndDo;
EndProcedure

&AtServer
Procedure MarkSettingForDeletion(ExchangeNode, DeletionMark)
	
	ObjectNode = ExchangeNode.GetObject();
	ObjectNode.DeletionMark = DeletionMark;
	Try
		ObjectNode.Write();
	Except
		Raise(ErrorDescription());
	EndTry
EndProcedure

&AtClient
Procedure AfterAnsweringQuestionMarkDelete(Val Result = Undefined, Val AdditionalParameters = Undefined) Export
	
	If Not Result = Undefined And Result = DialogReturnCode.Yes Then
		If AdditionalParameters.Property("IsFolder") Then
			MarkSettingsForDeletion(AdditionalParameters.ExchangeNode, Not AdditionalParameters.DeletionMark);
		Else
			MarkSettingForDeletion(AdditionalParameters.ExchangeNode, Not AdditionalParameters.DeletionMark);
		EndIf;
		Items.List.Refresh();
		ListWhenActivatingLineOnClient(Items.List.CurrentData);
	EndIf;
EndProcedure

&AtServer
Procedure CopyExchangeNode(Node, FormParameters)
	
	NodeAttributes = Common.ObjectAttributesValues(Node, "KindExchangeSettings, User, ExchangeSettings");
	FormParameters.Insert("User", NodeAttributes.User);
	FormParameters.Insert("KindExchangeSettings", NodeAttributes.KindExchangeSettings);
	FormParameters.Insert("ExchangeSettings", NodeAttributes.ExchangeSettings);
EndProcedure

&AtClient
Procedure ListWhenActivatingLineOnClient(CurrentRow)
	
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	VisibilityOfDeleteCommand = False;
	VisibilityOfCreateCommand = False;
	VisibilityOfCopyCommand = False;
	
	If CurrentRow.Property("RowGroup") Then
		If TypeOf(CurrentRow.RowGroup.Key) = Type("String") Then
			VisibilityOfCreateCommand = True;
		Else
			VisibilityOfCopyCommand = True;
		EndIf;
	Else
		VisibilityOfCopyCommand = True;
		VisibilityOfDeleteCommand = True;
		If CurrentRow.DeletionMark Then
			DeleteCommandHeader = NStr("vi = 'Bỏ dấu';
										|ru = 'Снять пометку';
										|en = 'Clear'; fa = 'پاک کردن';
										|it = 'Rimuovi il contrassegno';
										|pl = 'Usuń zaznaczenie';
										|tr = 'İşareti kaldır'");
		Else
			DeleteCommandHeader = NStr("vi = 'Đánh dấu xóa';
										|ru = 'Пометить на удаление';
										|en = 'Mark for deletion'; fa = 'علامت‌گذاری برای حذف';
										|it = 'Contrassegnare per la cancellazione';
										|pl = 'Zaznacz do usunięcia';
										|tr = 'Silmek için işaretle'");
		EndIf;
		Items.ListContextMenuMarkToDelete.Title = DeleteCommandHeader;
	EndIf;
	
	Items.ListContextMenuMarkToDelete.Visible = VisibilityOfDeleteCommand;
	Items.ListContextMenuCreateSetting.Visible = VisibilityOfCreateCommand;
	Items.ListContextMenuCopySetting.Visible = VisibilityOfCopyCommand;
EndProcedure

&AtServer
Procedure SetDynamicListParameters()
	
	QueryText = RequestTextForDynamicSettingsList();
	
	If Common.DataSeparationEnabled()
		And Common.SeparatedDataUsageAvailable() Then
		
		QueryText = StrReplace(QueryText, "InformationRegister.DataExchangesStates",
			"InformationRegister.DataAreaDataExchangeStates");
	EndIf;
	
	ListProperties = Common.DynamicListPropertiesStructure();
	ListProperties.MainTable = "ExchangePlan.MobileApplicationSalesOrders";
	ListProperties.DynamicDataRead = True;
	ListProperties.QueryText = QueryText;
	Common.SetDynamicListProperties(Items.List,
		ListProperties);
		
	If Parameters.Property("DoNotDisplayThisNode") Then
		List.Parameters.SetParameterValue("DoNotDisplayThisNode", Parameters.DoNotDisplayThisNode);
	Else
		List.Parameters.SetParameterValue("DoNotDisplayThisNode", False);
	EndIf;
	
	List.Parameters.SetParameterValue("EmptySetting", NStr("vi = 'Tùy chỉnh cá nhân';
															|ru = 'Индивидуальные настройки';
															|en = 'Individual settings'; fa = 'Individual settings';
															|it = 'Impostazioni individuali';
															|pl = 'Indywidualne ustawienia';
															|tr = 'Kişisel ayarlar'"));
	
	GroupingByTypeOfExchangeSettings = List.Group.Items.Add(Type("DataCompositionGroupField"));
	GroupingByTypeOfExchangeSettings.Field = New DataCompositionField("ExchangeSettingsGroup");
	GroupingByTypeOfExchangeSettings.Use = True;
EndProcedure

&AtServer
Function ListItemMarkedForDeletion(ListItem)
	
	Return Common.ObjectAttributeValue(ListItem, "DeletionMark");
EndFunction

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.List);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.List, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
EndProcedure
// End StandardSubsystems.AttachableCommands

&AtServer
Function RequestTextForDynamicSettingsList()
	
	Return "SELECT
	|	DataExchangesStates.InfobaseNode AS InfobaseNode,
	|	MAX(DataExchangesStates.EndDate) AS EndDate
	|INTO DataExchangeStatesMaxDate
	|FROM
	|	InformationRegister.DataExchangesStates AS DataExchangesStates
	|WHERE
	|	VALUETYPE(DataExchangesStates.InfobaseNode) = TYPE(ExchangePlan.MobileApplicationSalesOrders)
	|
	|GROUP BY
	|	DataExchangesStates.InfobaseNode
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DataExchangesStates.InfobaseNode AS InfobaseNode,
	|	MAX(CASE
	|			WHEN DataExchangesStates.ExchangeExecutionResult IS NULL
	|				THEN 0
	|			ELSE CASE
	|					WHEN DataExchangesStates.ExchangeExecutionResult = VALUE(Enum.ExchangeExecutionResults.Completed2)
	|						THEN 1
	|					ELSE 2
	|				END
	|		END) AS ExchangeStatus
	|INTO ExchangeExecutionResults
	|FROM
	|	InformationRegister.DataExchangesStates AS DataExchangesStates
	|		INNER JOIN DataExchangeStatesMaxDate AS DataExchangeStatesMaxDate
	|		ON (DataExchangeStatesMaxDate.InfobaseNode = DataExchangesStates.InfobaseNode)
	|			AND (DataExchangeStatesMaxDate.EndDate = DataExchangesStates.EndDate)
	|
	|GROUP BY
	|	DataExchangesStates.InfobaseNode
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	IntegrationWith1COrders.KindExchangeSettings AS KindExchangeSettings,
	|	COUNT(DISTINCT IntegrationWith1COrders.Ref) AS NumberOfItemsInGroup
	|INTO MessagingSettings
	|FROM
	|	ExchangePlan.MobileApplicationSalesOrders AS IntegrationWith1COrders
	|WHERE
	|	NOT IntegrationWith1COrders.KindExchangeSettings = VALUE(ExchangePlan.MobileApplicationSalesOrders.EmptyRef)
	|
	|GROUP BY
	|	IntegrationWith1COrders.KindExchangeSettings
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MobileApplicationSalesOrders.Ref AS Ref,
	|	MobileApplicationSalesOrders.DeletionMark AS DeletionMark,
	|	MobileApplicationSalesOrders.User AS User,
	|	MobileApplicationSalesOrders.PrefixForMobileDeviceData AS PrefixForMobileDeviceData,
	|	MobileApplicationSalesOrders.Description AS Description,
	|	CASE
	|		WHEN MobileApplicationSalesOrders.KindExchangeSettings = VALUE(ExchangePlan.MobileApplicationSalesOrders.EmptyRef)
	|			THEN CASE
	|					WHEN ISNULL(GroupSharingSettings.NumberOfItemsInGroup, 0) = 0
	|						THEN &EmptySetting
	|					ELSE MobileApplicationSalesOrders.Ref
	|				END
	|		ELSE MobileApplicationSalesOrders.KindExchangeSettings
	|	END AS ExchangeSettingsGroup,
	|	CASE
	|		WHEN MobileApplicationSalesOrders.KindExchangeSettings = VALUE(ExchangePlan.MobileApplicationSalesOrders.EmptyRef)
	|			THEN 0
	|		ELSE 1
	|	END AS Priority,
	|	ISNULL(DataExchangesStates.ExchangeStatus, 0) AS ExchangeStatus
	|FROM
	|	ExchangePlan.MobileApplicationSalesOrders AS MobileApplicationSalesOrders
	|		LEFT JOIN MessagingSettings AS GroupSharingSettings
	|		ON (GroupSharingSettings.KindExchangeSettings = MobileApplicationSalesOrders.Ref)
	|		LEFT JOIN ExchangeExecutionResults AS DataExchangesStates
	|		ON MobileApplicationSalesOrders.Ref = DataExchangesStates.InfobaseNode
	|WHERE
	|	CASE
	|			WHEN &DoNotDisplayThisNode
	|				THEN NOT MobileApplicationSalesOrders.ThisNode
	|		END";
EndFunction

#EndRegion
