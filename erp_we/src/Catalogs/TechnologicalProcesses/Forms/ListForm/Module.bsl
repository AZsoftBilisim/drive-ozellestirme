
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.GlobalCommandsGroup);
	// End IntegrationWith1CDocumentManagementSubsystem

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	CustomizeFormElements();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_TechnologicalProcesses" Then
		Items.List.Refresh();
	EndIf; 
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	SetSelectionByStatus(ThisForm);
	SetSelectionByDivision(ThisForm);
	SetSelectionByResponsible(ThisForm);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

#Region QuickFilters

&AtClient
Procedure FilterStatusOnChange(Item)
	
	SetSelectionByStatus(ThisForm);
	
EndProcedure

&AtClient
Procedure FilterDepartmentOnChange(Item)
	
	SetSelectionByDivision(ThisForm);
	
EndProcedure

&AtClient
Procedure FilterEmployeeResponsibleOnChange(Item)
	
	SetSelectionByResponsible(ThisForm);
	
EndProcedure

&AtClient
Procedure FilterProductsOnChange(Item)
	
	SetSelectionByProductRange();
	
EndProcedure

#EndRegion

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	If Var_Group Then
		Return;
	EndIf;
	
	If Copy Then
		
		Cancel = True;
		
		CopyTechnologicalProcess();
		
	ElsIf Not FilterProducts.IsEmpty() Then
		
		Cancel = True;
		
		FormParameters = New Structure;
		FormParameters.Insert("Basis", FilterProducts);
		OpenForm("Catalog.TechnologicalProcesses.ObjectForm", FormParameters);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure TheSetStatusInDevelopmentCommand(Command)
	
	SetStatus("UnderDevelopment", NStr("vi = 'Đang phát triển';
										|ru = 'В разработке';
										|en = 'Under development'; fa = 'در حال توسعه';
										|it = 'In elaborazione';
										|pl = 'W opracowaniu';
										|tr = 'Geliştirme aşamasında'"));
	
EndProcedure

&AtClient
Procedure TheSetStatusCommandIsActive(Command)
	
	SetStatus("Valid", NStr("vi = 'Có hiệu lực';
							|ru = 'Действует';
							|en = 'Valid'; fa = 'معتبر';
							|it = 'In vigore';
							|pl = 'Aktualne';
							|tr = 'Aktif'"));
	
EndProcedure

&AtClient
Procedure SetStatusClosedCommand(Command)
	
	SetStatus("Closed", NStr("vi = 'Đã đóng';
							|ru = 'Закрыт';
							|en = 'Closed'; fa = 'بسته‌شده';
							|it = 'Chiuso';
							|pl = 'Zamknij';
							|tr = 'Kapalı'"));
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.List);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure ChangeSelectedItems(Command)
	
	BatchEditObjectsClient.ChangeSelectedItems(Items.List);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure CustomizeFormElements()
	
	ChangeSelectedAvailable = ProductionServer.CommandChangeSelectedIsAvailable(Metadata.Catalogs.TechnologicalProcesses);
	Items.ListChangeSelectedItems.Visible                      = ChangeSelectedAvailable;
	Items.ContextMenuChangeSelected.Visible = ChangeSelectedAvailable;
	
EndProcedure

#Region Filters

&AtClientAtServerNoContext
Procedure SetSelectionByStatus(Form)

	CommonClientServer.SetDynamicListFilterItem(
		Form.List, 
		"Status", 
		Form.FilterStatus, 
		DataCompositionComparisonType.Equal,
		, 
		ValueIsFilled(Form.FilterStatus));

EndProcedure

&AtClientAtServerNoContext
Procedure SetSelectionByDivision(Form)

	CommonClientServer.SetDynamicListFilterItem(
		Form.List, 
		"Department", 
		Form.FilterDepartment, 
		DataCompositionComparisonType.Equal,
		, 
		ValueIsFilled(Form.FilterDepartment));

EndProcedure

&AtClientAtServerNoContext
Procedure SetSelectionByResponsible(Form)

	CommonClientServer.SetDynamicListFilterItem(
		Form.List, 
		"EmployeeResponsible", 
		Form.FilterEmployeeResponsible, 
		DataCompositionComparisonType.Equal,
		, 
		ValueIsFilled(Form.FilterEmployeeResponsible));
	
EndProcedure

&AtServer
Procedure SetSelectionByProductRange()
	
	Catalogs.TechnologicalProcesses.SetSelectionByProductInListOfTechnologicalProcesses(
		List,
		FilterProducts);
	
EndProcedure

#EndRegion

#Region SettingStatus

&AtClient
Procedure SetStatus(StatusValue, StatusPresentation)

	HighlightedLinks = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.List);
	
	If HighlightedLinks.Count() = 0 Then
		Return
	EndIf;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("StatusValue",      StatusValue);
	AdditionalParameters.Insert("StatusPresentation", StatusPresentation);
	AdditionalParameters.Insert("HighlightedLinks",     HighlightedLinks);
	CallbackDescription = New CallbackDescription("SetStatusCompletion", ThisObject, AdditionalParameters);
	
	QueryText = NStr("vi = 'Các quy trình kỹ thuật đã chọn sẽ được đặt trạng thái ""%1"". Tiếp tục?';
					|ru = 'Выбранным технологическим процессам будет установлен статус ""%1"". Продолжить?';
					|en = 'The selected technological processes will be set to ""%1"" status. Continue?'; fa = 'The selected technological processes will be set to ""%1"" status. Continue?';
					|it = 'Ai processi tecnologici selezionati verrà impostato lo stato ""%1"". Continuare?';
					|pl = 'Dla wybranych procesów technologicznych zostanie ustawiony status ""%1"". Kontynuować?';
					|tr = 'Seçili teknolojik süreçte ""%1"" durumu ayarlanacaktır. Devam edilsin mi?'");
	QueryText = StringFunctionsClientServer.SubstituteParametersToString(QueryText, StatusPresentation);
	
	ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure SetStatusCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	ClearMessages();
	
	ProcessedItemsCount = SetStatusOnServer(
			AdditionalParameters.HighlightedLinks, 
			AdditionalParameters.StatusValue);
										
	TMCommonUseClient.NotifyUserAboutSettingStatus(
			Undefined,
			ProcessedItemsCount, 
			AdditionalParameters.HighlightedLinks.Count(), 
			AdditionalParameters.StatusPresentation);
			
	Notify("Write_TechnologicalProcesses");
	NotifyChanged(Type("CatalogRef.TechnologicalProcesses"));
	
EndProcedure

&AtServerNoContext
Function SetStatusOnServer(HighlightedLinks, StatusValue) Export
	NewStatus = Enums.TechnologicalProcessStatuses[StatusValue];
	
	Query = New Query;
	Query.Text = 
	"SELECT ALLOWED
	|	TechnologicalProcesses.Ref,
	|	TechnologicalProcesses.Description,
	|	TechnologicalProcesses.DeletionMark
	|FROM
	|	Catalog.TechnologicalProcesses AS TechnologicalProcesses
	|WHERE
	|	TechnologicalProcesses.Status <> &NewStatus
	|	AND TechnologicalProcesses.Ref IN(&HighlightedLinks)";
	
	Query.SetParameter("HighlightedLinks", HighlightedLinks);
	Query.SetParameter("NewStatus",      NewStatus);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	ProcessedItemsCount = 0;
	
	If NewStatus = Enums.TechnologicalProcessStatuses.UnderDevelopment Then
		StorageAddress = PutToTempStorage(Undefined);
	EndIf;
	
	While Selection.Next() Do
		
		If Selection.DeletionMark Then
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
									NStr("vi = 'Không nên thay đổi trạng thái các quy trình kỹ thuật đã đặt dấu xóa ""%1"".';
										|ru = 'Нельзя изменить статус помеченного на удаление технологического процесса""%1"".';
										|en = 'Cannot change the status of a technological process ""%1"" marked for deletion.'; fa = 'Cannot change the status of a technological process ""%1"" marked for deletion.';
										|it = 'Impossibile modificare lo stato del processo tecnologico ""%1"" contrassegnato per l''eliminazione.';
										|pl = 'Nie można zmienić statusu zaznaczonego do usunięcia procesu technologicznego""%1"".';
										|tr = 'Silinmek üzere işaretlenen ""%1""teknolojik sürecinin durumu değiştirilemez.'"),
									Selection.Description);
									
			CommonClientServer.MessageToUser(MessageText, Selection.Ref); 
			Continue;
		EndIf;
		
		CatObject = Selection.Ref.GetObject();
		
		BeginTransaction();
		
		Try
			
			If NewStatus = Enums.TechnologicalProcessStatuses.UnderDevelopment Then
				CheckParameters = New Structure("Object", Selection.Ref);
				Catalogs.TechnologicalProcesses.CheckObjectUsage(CheckParameters, StorageAddress);
				ThereAreRefs = GetFromTempStorage(StorageAddress);
				If ThereAreRefs Then
					MessageText = StringFunctionsClientServer.SubstituteParametersToString(
											NStr("vi = 'Quy trình kỹ thuật ""%1"" đang sử dụng. Chỉ được phép đặt trạng thái ""Đang phát triển"" trong biểu mẫu quy trình kỹ thuật.';
												|ru = 'Технологический процесс ""%1"" используется. Установка статуса ""В разработке"" допускается только в форме технологического процесса.';
												|en = 'Technological process ""%1"" is in use. Setting the ""Under development"" status is only allowed in the technological process form.'; fa = 'Technological process ""%1"" is in use. Setting the ""Under development"" status is only allowed in the technological process form.';
												|it = 'Il processo tecnologico ""%1"" è in uso. L''impostazione dello stato ""In elaborazione"" è ammessa solo nel modulo del processo tecnologico.';
												|pl = 'Proces technologiczny ""%1"" jest używane. Ustawienie statusu ""W przygotowaniu"" dopuszczalne jest tylko w formularzu procesu technologicznego.';
												|tr = '""%1"" teknolojik süreci kullanılmaktadır. ""Geliştirme aşamasında"" durumunun yapılandırılmasına sadece teknolojik süreç formunda izin verilmektedir.'"),
											CatObject.Description);
											
					CommonClientServer.MessageToUser(MessageText, Selection.Ref); 
					RollbackTransaction();
					Continue;
				EndIf;
			EndIf; 
			
			CatObject.Status = NewStatus;
			If CatObject.CheckFilling() Then
				CatObject.Write();
			EndIf;
			CommitTransaction();
		Except
			RollbackTransaction();
			Continue;
		EndTry;
		ProcessedItemsCount = ProcessedItemsCount + 1;
		
	EndDo;
	
	Return ProcessedItemsCount;

EndFunction

#EndRegion

#Region Other

&AtServer
Procedure SetConditionalAppearance()
	
	List.ConditionalAppearance.Items.Clear();
	Catalogs.TechnologicalProcesses.EstablishConditionalAppearanceOfListOfTechnologicalProcesses(List.ConditionalAppearance);
	
EndProcedure

&AtClient
Procedure CopyTechnologicalProcess()
	
	CallbackDescription = New CallbackDescription("QuestionCopyTechnologicalProcess", ThisForm);
	
	ProductDataManagementClient.ShowQuestionCopyWorkflowWithOperations(CallbackDescription)
	
EndProcedure

&AtClient
Procedure QuestionCopyTechnologicalProcess(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	Ref = CopyWorkflowOnServer(Items.List.CurrentData.Ref);
	
	If Ref <> Undefined Then
		
		Items.List.CurrentRow = Ref;
		
		ProductDataManagementClient.NotifyAboutCopyingTechnologicalProcessWithOperations();
		
		OpenForm("Catalog.TechnologicalProcesses.ObjectForm", New Structure("Key", Ref));
	
	EndIf; 

EndProcedure

&AtServerNoContext
Function CopyWorkflowOnServer(Source)
	
	Return Catalogs.TechnologicalProcesses.CopyWorkflowWithOperations(Source);
	
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

#EndRegion

#EndRegion
