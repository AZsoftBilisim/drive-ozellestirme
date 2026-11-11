#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	Items.CreateBusinessRegionsForm.Visible = AccessRight("Update", Metadata.Catalogs.BusinessRegions);
	
	CanBeEdited = AccessRight("Edit", Metadata.Catalogs.BusinessRegions);
	Items.FormChangeSelectedItems.Visible = CanBeEdited;
	Items.ListContextMenuChangeSelectedItems.Visible = CanBeEdited;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
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

&AtClient
Procedure ChangeSelectedItems(Command)
	
	BatchEditObjectsClient.ChangeSelectedItems(Items.List);
	
EndProcedure

&AtClient
Procedure FillInBusinessRegions(Command)
	
	If Not GeographicalMapForReportsIsFilledIn() Then
		WarningText = NStr("vi = 'Chưa chọn thẻ ""CRM và bán hàng"" trong phân hệ quản trị hệ thống. Không thể điền khu vực địa lý.';
							|ru = 'Не выбрана карта в разделе администрирования ""CRM и продажи"". Географические регионы не могут быть заполнены.';
							|en = 'No map is selected in ""Master data and settings – CRM and marketing"". Cannot fill in geographic regions.'; fa = 'No map is selected in ""Master data and settings – CRM and marketing"". Cannot fill in geographic regions.';
							|it = 'Non è stata selezionata una mappa nella sezione di gestione ""CRM e vendite"". Le aree geografiche non possono essere compilate.';
							|pl = 'Nie wybrano mapy w rozdziale administrowania ""CRM и продажи"". Regiony geograficzne nie mogą zostać wypełnione.';
							|tr = '""CRM ve satış"" yönetim bölümünde kart seçilmedi. Coğrafi bölgeler doldurulmamalı.'");
		ShowMessageBox(Undefined, WarningText);
	Else
		CallbackDescription = New CallbackDescription("UpdateListOfBusinessRegions", ThisObject);
		OpenForm("Catalog.BusinessRegions.Form.BusinessRegionGenerationForm",, ThisForm,,,, CallbackDescription,);
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

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

#EndRegion

#Region Private

&AtClient
Procedure UpdateListOfBusinessRegions(ClosingResult, AdditionalParameters) Export
	
	If TypeOf(ClosingResult) = Type("Number") Then
		If ClosingResult Then
			Items.List.Refresh();
			UserNotificationText = NStr("vi = 'Đã ghi lại khu vực kinh doanh mới: %1';
										|ru = 'Записано новых бизнес-регионов: %1';
										|en = 'New business regions saved: %1'; fa = 'New business regions saved: %1';
										|it = 'Nuove aree commerciali registrate: %1';
										|pl = 'Zapisano nowych regionów biznesowych: %1';
										|tr = 'Kaydedilen yeni iş bölgeleri: %1'");
			UserNotificationText = 
				StringFunctionsClientServer.SubstituteParametersToString(UserNotificationText, ClosingResult);
		Else
			UserNotificationText = NStr("vi = 'Đã tìm thấy tất cả khu vực được chọn.';
										|ru = 'Все выбранные регионы найдены.';
										|en = 'All selected regions are found.'; fa = 'All selected regions are found.';
										|it = 'Tutte le aree selezionate sono state trovate.';
										|pl = 'Wszystkie wybrane regiony zostały znalezione.';
										|tr = 'Seçilen tüm bölgeler bulunur.'");
		EndIf;
		ShowUserNotification(UserNotificationText);
	EndIf;
	
EndProcedure

&AtServerNoContext
Function GeographicalMapForReportsIsFilledIn()
	
	Return ValueIsFilled(Constants.GeographicDiagramForReports.Get().Get());
	
EndFunction

#EndRegion

