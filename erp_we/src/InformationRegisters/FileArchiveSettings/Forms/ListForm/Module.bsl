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

	If Not Parameters.IsOpeningFormAllowed Then
		ErrorText = NStr("ru = 'Произвольное открытие формы не предусмотрено.';
						|vi = 'Cannot open this form directly.';
						|en = 'Cannot open this form directly.'; fa = 'Cannot open this form directly.';
						|it = 'Cannot open this form directly.';
						|pl = 'Cannot open this form directly.';
						|tr = 'Formun rastgele açılması öngörülmemiştir.'");
		Raise ErrorText;
	EndIf;
	
	FillObjectTypesInValueTree();

	IsFilesTransferManualStartAvailable = Not Common.DataSeparationEnabled() And Common.SubsystemExists("StandardSubsystems.ScheduledJobs");
	
	Items.GroupFilesTransferExecutionState.Visible = IsFilesTransferManualStartAvailable;
	Items.MoveFiles.Visible = IsFilesTransferManualStartAvailable;

	If IsFilesTransferManualStartAvailable Then

		Items.LabelCurrentState.Title = GetFilesTransferOperationsExecutionCurrentStatusPresentation();

	EndIf;

EndProcedure
#EndRegion

#Region FormTableItemsEventHandlersMetadataObjectsTree

&AtClient
Procedure MetadataObjectsTreeBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)

	Cancel = True;
	If Not Copy Then
		AttachIdleHandler("AddFileArchiveWorkSettings", 0.1, True);
	EndIf;	

EndProcedure

&AtClient
Procedure MetadataObjectsTreeOnActivateField(Item)

	Item.CurrentItem.ReadOnly = Not FormTableGetItemAvailabilityToEdit(Item);

EndProcedure

&AtClient
Procedure MetadataObjectsTreeActionOnChange(Item)

	WriteCurrentSettings();

EndProcedure

&AtClient
Procedure MetadataObjectsTreeArchiveAfterDaysOnChange(Item)

	If Not SettingIsFilledInCorrectly() Then
		Return;		
	EndIf;
	
	WriteCurrentSettings();

EndProcedure

&AtClient
Procedure MetadataObjectsTreeActionClearing(Item, StandardProcessing)

	StandardProcessing = False;	
	SetActionForSelectedObjects(PredefinedValue("Enum.FileArchivingBehavior.DontAddToArchive"));

EndProcedure

&AtClient
Procedure MetadataObjectsTreeBeforeRowChange(Item, Cancel)

	Cancel = Not FormTableGetItemAvailabilityToEdit(Item); // ACC:144 - The function returns a Boolean value.

EndProcedure

&AtClient
Procedure MetadataObjectsTreeChoiceProcessing(Item, ValueSelected, StandardProcessing)

	StandardProcessing = False;
	AddSettingsByOwner(ValueSelected);

EndProcedure

&AtClient
Procedure MetadataObjectsTreeBeforeDeleteRow(Item, Cancel)

	Cancel = True;

	SettingToDelete = MetadataObjectsTree.FindByID(Items.MetadataObjectsTree.CurrentRow);
	If SettingToDelete <> Undefined Then

		SettingToDeleteParent = SettingToDelete.GetParent();

		If SettingToDeleteParent <> Undefined And SettingToDeleteParent.DetailedInfoAvailable Then

			QueryText = NStr("ru = 'Удаление настройки приведет к прекращению использования
				|заданных в ней правил. Продолжить?';
				|vi = 'If you delete the setting, you will not be able
				|to use the rules defined in it. Continue?';
				|en = 'If you delete the setting, you will not be able
				|to use the rules defined in it. Continue?'; fa = 'If you delete the setting, you will not be able
				|to use the rules defined in it. Continue?';
				|it = 'If you delete the setting, you will not be able
				|to use the rules defined in it. Continue?';
				|pl = 'If you delete the setting, you will not be able
				|to use the rules defined in it. Continue?';
				|tr = 'Ayarın silinmesi, içinde belirtilen 
				| kurallarının kullanımının durdurulmasına neden olacaktır. Devam edilsin mi?'");
			CallbackDescription = New CallbackDescription("DeleteSettingItemCompletion", ThisObject);
			ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo, , DialogReturnCode.No, NStr("ru = 'Предупреждение';
																												|vi = 'Warning';
																												|en = 'Warning'; fa = 'هشدار';
																												|it = 'Warning';
																												|pl = 'Warning';
																												|tr = 'Uyarı'"));
			Return;

		EndIf;

	EndIf;

	MessageText = NStr("ru = 'Расширенная настройка работы с файловым архивом не предусмотрена для этого объекта.';
						|vi = 'Advanced file archive settings are unavailable for this object.';
						|en = 'Advanced file archive settings are unavailable for this object.'; fa = 'Advanced file archive settings are unavailable for this object.';
						|it = 'Advanced file archive settings are unavailable for this object.';
						|pl = 'Advanced file archive settings are unavailable for this object.';
						|tr = 'Bu nesne için dosya arşivi ile gelişmiş çalışma ayarı öngörülmemiştir.'");
	ShowMessageBox(, MessageText);

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure MoveFiles(Command)
	CancelBackgroundJob1();
	RunScheduledJob();

	AttachIdleHandler("CheckBackgroundJobExecution", 2, True);

EndProcedure

#EndRegion

#Region Private
&AtServer
Procedure FillObjectTypesInValueTree()

	FileArchiveSettings = InformationRegisters.FileArchiveSettings.FileArchiveOperationsCurrentSettings();

	MOTree = FormAttributeToValue("MetadataObjectsTree");
	MOTree.Rows.Clear();

	MetadataCatalogs = Metadata.Catalogs;

	TypesTable = New ValueTable;
	TypesTable.Columns.Add("FileOwner");
	TypesTable.Columns.Add("FileOwnerType");
	TypesTable.Columns.Add("FileOwnerName");
	TypesTable.Columns.Add("IsFile", New TypeDescription("Boolean"));
	TypesTable.Columns.Add("DetailedInfoAvailable"  , New TypeDescription("Boolean"));

	For Each Catalog In MetadataCatalogs Do

		If Catalog.Attributes.Find("FileOwner") = Undefined Then
			Continue;
		EndIf;

		FilesOwnersTypes = Catalog.Attributes.FileOwner.Type.Types();
		For Each OwnerType In FilesOwnersTypes Do
			
			OwnerMetadata = Metadata.FindByType(OwnerType);
			
			NewRow = TypesTable.Add();
			NewRow.FileOwner = OwnerType;
			NewRow.FileOwnerType = Catalog;
			NewRow.FileOwnerName = OwnerMetadata.FullName();
			NewRow.DetailedInfoAvailable = True;
			
			If Not StrEndsWith(Catalog.Name, FilesOperationsInternal.CatalogSuffixAttachedFiles()) Then
				NewRow.IsFile = True;
			EndIf;
			
		EndDo;
		
	EndDo;

	AllCatalogs = Catalogs.AllRefsType();

	AllDocuments = Documents.AllRefsType();
	CatalogsNode = Undefined;
	DocumentsNode = Undefined;
	BusinessProcessesNode = Undefined;

	CommonSettingsNode = MOTree.Rows.Add();
	CommonSettingsNode.ObjectDescriptionSynonym	= NStr("ru = 'Общие настройки';
															|vi = 'General settings';
															|en = 'General settings'; fa = 'تنظیمات عمومی';
															|it = 'Impostazioni principali';
															|pl = 'Ustawienia ogólne';
															|tr = 'Genel ayarlar'");	

	CommonSettings = FileArchiveSettings.FindRows(New Structure("FileOwner, FileOwnerType", Undefined, Undefined));
	If CommonSettings.Count() > 0 Then

		CommonSettingsNode.ArchiveAfterDays	= CommonSettings[0].ArchiveAfterDays;

	EndIf;

	FilesOwners = New Array;
	For Each Type In TypesTable Do
		
		FileOwnerType = Type.FileOwnerType; // MetadataObjectCatalog
		If StrStartsWith(FileOwnerType.Name, "Delete")
			Or FilesOwners.Find(Type.FileOwnerName) <> Undefined Then
			Continue;
		EndIf;

		FilesOwners.Add(Type.FileOwnerName);

		If AllCatalogs.ContainsType(Type.FileOwner) Then
			If CatalogsNode = Undefined Then
				CatalogsNode = MOTree.Rows.Add();
				CatalogsNode.ObjectDescriptionSynonym = NStr("vi = 'Danh mục';
															|ru = 'Справочники';
															|en = 'Catalogs'; fa = 'فهرست‌ها';
															|it = 'Directory';
															|pl = 'Kartoteki';
															|tr = 'Kataloglar'");
			EndIf;
			NewTableRow = CatalogsNode.Rows.Add();
		ElsIf AllDocuments.ContainsType(Type.FileOwner) Then
			If DocumentsNode = Undefined Then
				DocumentsNode = MOTree.Rows.Add();
				DocumentsNode.ObjectDescriptionSynonym = NStr("vi = 'Chứng từ';
																|ru = 'Документы';
																|en = 'Documents'; fa = 'اسناد';
																|it = 'Documenti';
																|pl = 'Documents';
																|tr = 'Belgeler'");
			EndIf;
			NewTableRow = DocumentsNode.Rows.Add();
		ElsIf BusinessProcesses.AllRefsType().ContainsType(Type.FileOwner) Then
			If BusinessProcessesNode = Undefined Then
				BusinessProcessesNode = MOTree.Rows.Add();
				BusinessProcessesNode.ObjectDescriptionSynonym = NStr("vi = 'Quy trình nghiệp vụ';
																		|ru = 'Бизнес-процессы';
																		|en = 'Business processes'; fa = 'فرایندهای تجاری';
																		|it = 'Processi aziendali';
																		|pl = 'Business processes';
																		|tr = 'İş süreçleri'");
			EndIf;
			NewTableRow = BusinessProcessesNode.Rows.Add();
		EndIf;
		ObjectMetadata = Metadata.FindByType(Type.FileOwner);
		NewTableRow.FileOwner = Common.MetadataObjectID(Type.FileOwner);
		NewTableRow.FileOwnerType = Common.MetadataObjectID(Type.FileOwnerType);
		NewTableRow.ObjectDescriptionSynonym = ObjectMetadata.Synonym;
		NewTableRow.IsFile = Type.IsFile;
		NewTableRow.DetailedInfoAvailable = Type.DetailedInfoAvailable;
		
		ObjectID		= Common.MetadataObjectID(Type.FileOwner);
		DetailedSettings	= FileArchiveSettings.FindRows(New Structure(
										"OwnerID, IsFile", ObjectID, Type.IsFile));

		If DetailedSettings.Count() > 0 Then
			For Each Setting In DetailedSettings Do
				DetalizedSetting = NewTableRow.Rows.Add();
				DetalizedSetting.FileOwner						= Setting.FileOwner;
				DetalizedSetting.FileOwnerType					= Setting.FileOwnerType;
				DetalizedSetting.ObjectDescriptionSynonym		= Setting.FileOwner;
				DetalizedSetting.Action							= Setting.Action;
				DetalizedSetting.ArchiveAfterDays	= Setting.ArchiveAfterDays;
				DetalizedSetting.IsFile							= Setting.IsFile;
			EndDo;
		EndIf;		
		
		FoundSettings = FileArchiveSettings.FindRows(New Structure("FileOwner, IsFile", NewTableRow.FileOwner, Type.IsFile));

		If FoundSettings.Count() > 0 Then
			NewTableRow.Action							= FoundSettings[0].Action;
			NewTableRow.ArchiveAfterDays	= FoundSettings[0].ArchiveAfterDays;
		Else
			NewTableRow.Action							= Enums.FileArchivingBehavior.DontAddToArchive;
			NewTableRow.ArchiveAfterDays	= 0;
		EndIf;
	EndDo;
	
	For Each TopLevelNode In MOTree.Rows Do
		TopLevelNode.Rows.Sort("ObjectDescriptionSynonym");
	EndDo;
	ValueToFormAttribute(MOTree, "MetadataObjectsTree");
	
EndProcedure

&AtClient
Function FormTableGetItemAvailabilityToEdit(Item)

	Result = True;

	If Item.CurrentItem.Name = "MetadataObjectsTreeObjectDescriptionSynonym" Then
		Result = False;
	ElsIf Item.CurrentData.FileOwnerType = Undefined Then
		Result = Item.CurrentItem.Name = "MetadataObjectsTreeArchiveAfterDays";
	EndIf;

	Return Result;

EndFunction

&AtClient
Procedure AddFileOwner(SelectedOwners, ObjectTreeRow)
	If TypeOf(ObjectTreeRow.FileOwner) = Type("CatalogRef.MetadataObjectIDs")
	   Or TypeOf(ObjectTreeRow.FileOwner) = Type("CatalogRef.ExtensionObjectIDs")
	   Or ObjectTreeRow.FileOwner = Undefined Then
		SubordinateRows = ObjectTreeRow.GetItems();
		For Each TreeRow In SubordinateRows Do
			AddFileOwner(SelectedOwners, TreeRow);
		EndDo;
	Else
		If SelectedOwners.Find(ObjectTreeRow.FileOwner) = Undefined Then
			SelectedOwners.Add(ObjectTreeRow.FileOwner);
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure DeleteSettingItemCompletion(Result, AdditionalParameters) Export

	If Result = DialogReturnCode.Yes Then
		ClearSettingData();
	EndIf;

EndProcedure

&AtClient
Procedure AddFileArchiveWorkSettings()

	TreeRow = Items.MetadataObjectsTree.CurrentData;

	If Not TreeRow.DetailedInfoAvailable Then
		MessageText = NStr("ru = 'Расширенная настройка работы с файловым архивом не предусмотрена для этого объекта.';
							|vi = 'Advanced file archive settings are unavailable for this object.';
							|en = 'Advanced file archive settings are unavailable for this object.'; fa = 'Advanced file archive settings are unavailable for this object.';
							|it = 'Advanced file archive settings are unavailable for this object.';
							|pl = 'Advanced file archive settings are unavailable for this object.';
							|tr = 'Bu nesne için dosya arşivi ile gelişmiş çalışma ayarı öngörülmemiştir.'");
		ShowMessageBox(, MessageText);
		Return;
	EndIf;

	ChoiceFormParameters = New Structure;

	ChoiceFormParameters.Insert("ChoiceFoldersAndItems"			, FoldersAndItemsUse.FoldersAndItems);
	ChoiceFormParameters.Insert("CloseOnChoice"				, True);
	ChoiceFormParameters.Insert("CloseOnOwnerClose"	, True);
	ChoiceFormParameters.Insert("MultipleChoice"				, True);
	ChoiceFormParameters.Insert("ChoiceMode"						, True);

	ChoiceFormParameters.Insert("WindowOpeningMode"		, FormWindowOpeningMode.LockOwnerWindow);
	ChoiceFormParameters.Insert("SelectGroups"				, True);
	ChoiceFormParameters.Insert("UsersGroupsSelection"	, True);

	ChoiceFormParameters.Insert("AdvancedPick"		, True);
	ChoiceFormParameters.Insert("PickFormHeader"	, NStr("ru = 'Подбор элементов настроек';
															|vi = 'Select settings items';
															|en = 'Select settings items'; fa = 'Select settings items';
															|it = 'Selezione elementi delle impostazioni';
															|pl = 'Dobór elementów ustalania';
															|tr = 'Ayar öğelerinin seçimi'"));

	// Excluding already existing settings from the selection list.
	ExistingSettings1 = TreeRow.GetItems();
	FixedSettings = New DataCompositionSettings;
	SettingItem = FixedSettings.Filter.Items.Add(Type("DataCompositionFilterItem"));
	SettingItem.LeftValue = New DataCompositionField("Ref");
	SettingItem.ComparisonType = DataCompositionComparisonType.NotInList;
	ExistingSettingsList = New Array;
	For Each Setting In ExistingSettings1 Do
		ExistingSettingsList.Add(Setting.FileOwner);
	EndDo;
	SettingItem.RightValue = ExistingSettingsList;
	SettingItem.Use = True;
	SettingItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	ChoiceFormParameters.Insert("FixedSettings", FixedSettings);

	OpenForm(ChoiceFormPath(TreeRow.FileOwner), ChoiceFormParameters, Items.MetadataObjectsTree);

EndProcedure

&AtServer
Function ChoiceFormPath(Val FileOwner)

	MetadataObject = Common.MetadataObjectByID(FileOwner);
	Return MetadataObject.FullName() + ".ChoiceForm";

EndFunction

&AtServer
Procedure AddSettingsByOwner(Val ValueSelected)

	RowOwner = MetadataObjectsTree.FindByID(Items.MetadataObjectsTree.CurrentRow);


	RecordStructureOfRegister = InformationRegisters.FileArchiveSettings.StructureOfRecord();
	FillPropertyValues(RecordStructureOfRegister, RowOwner);
	InformationRegisters.FileArchiveSettings.AddRecord(RecordStructureOfRegister);

	OwnerElement = RowOwner.GetItems();
	For Each Setting In ValueSelected Do

		RecordStructureOfRegister = InformationRegisters.FileArchiveSettings.StructureOfRecord();
		RecordStructureOfRegister.FileOwner						= Setting;
		RecordStructureOfRegister.FileOwnerType					= RowOwner.FileOwnerType;
		RecordStructureOfRegister.Action							= Enums.FileArchivingBehavior.DontAddToArchive;
		RecordStructureOfRegister.ArchiveAfterDays	= RowOwner.ArchiveAfterDays;
		RecordStructureOfRegister.IsFile								= RowOwner.IsFile;

		InformationRegisters.FileArchiveSettings.AddRecord(RecordStructureOfRegister);

		DetalizedSetting = OwnerElement.Add();
		FillPropertyValues(DetalizedSetting, RecordStructureOfRegister);
		DetalizedSetting.ObjectDescriptionSynonym = Setting;
	EndDo;
	
EndProcedure

&AtServer
Procedure ClearSettingData()

	SettingToDelete = MetadataObjectsTree.FindByID(Items.MetadataObjectsTree.CurrentRow);

	InformationRegisters.FileArchiveSettings.DeleteRecord(SettingToDelete.FileOwner, SettingToDelete.FileOwnerType);

	SettingsItemParent = SettingToDelete.GetParent();
	If SettingsItemParent <> Undefined Then
		SettingsItemParent.GetItems().Delete(SettingToDelete);
	Else
		MetadataObjectsTree.GetItems().Delete(SettingToDelete);
	EndIf;

EndProcedure

&AtServer
Procedure SetActionForSelectedObjects(Val Action)

	For Each RowID In Items.MetadataObjectsTree.SelectedRows Do
		TreeItem = MetadataObjectsTree.FindByID(RowID);
		If TreeItem.GetParent() = Undefined Then
			For Each TreeChildItem In TreeItem.GetItems() Do
				SetActionOfSelectedObjectWithRecursion(TreeChildItem, Action);
			EndDo;
		Else
			SetActionOfSelectedObjectWithRecursion(TreeItem, Action);
		EndIf;
	EndDo;

EndProcedure

&AtServer
Procedure SetActionOfSelectedObjectWithRecursion(SelectedObject, Val Action)

	SetSelectedObjectAction(SelectedObject, Action);
	For Each ChildObject In SelectedObject.GetItems() Do
		SetSelectedObjectAction(ChildObject, Action);
	EndDo;

EndProcedure

&AtServer
Procedure SetSelectedObjectAction(SelectedObject, Val Action)

	SelectedObject.Action = Action;
	SaveCurrentObjectSettings(
		SelectedObject.FileOwner,
		SelectedObject.FileOwnerType,
		Action,
		SelectedObject.ArchiveAfterDays,
		SelectedObject.IsFile);

EndProcedure

&AtClient
Procedure WriteCurrentSettings()

	CurrentData = Items.MetadataObjectsTree.CurrentData;
	SaveCurrentObjectSettings(
		CurrentData.FileOwner,
		CurrentData.FileOwnerType,
		CurrentData.Action,
		CurrentData.ArchiveAfterDays,
		CurrentData.IsFile);

EndProcedure

&AtServer
Procedure SaveCurrentObjectSettings(Val FileOwner, Val FileOwnerType, Val Action, Val ArchiveAfterDays, Val IsFile)

	RecordStructureOfRegister = InformationRegisters.FileArchiveSettings.StructureOfRecord();
	RecordStructureOfRegister.FileOwner						= FileOwner;
	RecordStructureOfRegister.FileOwnerType					= FileOwnerType;
	RecordStructureOfRegister.Action							= Action;
	RecordStructureOfRegister.ArchiveAfterDays	= ArchiveAfterDays;
	RecordStructureOfRegister.IsFile								= IsFile;
	
	InformationRegisters.FileArchiveSettings.AddRecord(RecordStructureOfRegister);

EndProcedure

&AtServer
Procedure RunScheduledJob()

	If Not Common.SubsystemExists("StandardSubsystems.ScheduledJobs") Then
		Return;
	EndIf;
	
	ModuleScheduledJobsInternal = Common.CommonModule("ScheduledJobsInternal");
	
	RaiseIfNoAdministrationRights(ModuleScheduledJobsInternal);

	ScheduledJobMetadata1 = Metadata.ScheduledJobs.TransferFilesBetweenOperationalStorageAndArchive;

	Filter = New Structure;
	MethodName = ScheduledJobMetadata1.MethodName;
	Filter.Insert("MethodName", MethodName);
	Filter.Insert("State", BackgroundJobState.Active);
	FilesTransferBackgroundJobs = BackgroundJobs.GetBackgroundJobs(Filter);
	If FilesTransferBackgroundJobs.Count() > 0 Then
		BackgroundJobIdentifier = FilesTransferBackgroundJobs[0].UUID;
	Else

		ScheduledJob = ScheduledJobs.FindPredefined(ScheduledJobMetadata1); // ACC:453 - Used only in shared mode.

		ExecutionParameters = ModuleScheduledJobsInternal.ExecuteScheduledJobManually(ScheduledJob.UUID);		

		BackgroundJobIdentifier = New UUID(ExecutionParameters.BackgroundJobIdentifier);

		Items.LabelCurrentState.Title = GetFilesTransferOperationsExecutionCurrentStatusPresentation(BackgroundJobIdentifier)

	EndIf;
EndProcedure

&AtClient
Procedure CancelBackgroundJob1()
	CancelJobExecution(BackgroundJobIdentifier);
	BackgroundJobIdentifier = "";
EndProcedure

&AtServerNoContext
Procedure CancelJobExecution(Val BackgroundJobIdentifier)

	If ValueIsFilled(BackgroundJobIdentifier) And Common.SubsystemExists("StandardSubsystems.ScheduledJobs") Then

		RaiseIfNoAdministrationRights();

		TimeConsumingOperations.CancelJobExecution(BackgroundJobIdentifier);
	EndIf;
EndProcedure

&AtClient
Function SettingIsFilledInCorrectly()

	Result = True;

	CurrentData = Items.MetadataObjectsTree.CurrentData;

	If CurrentData.FileOwner = Undefined And CurrentData.FileOwnerType = Undefined Then
		If CurrentData.ArchiveAfterDays = 0 Then

			Result = False;

			CurrentData.ArchiveAfterDays = GetDefaultSettingCurrentValue();

			MessageText = NStr("ru = 'Значение общих настроек хранения файлов должно быть обязательно заполнено
									|Восстановлено старое значение.';
									|vi = 'General file storage settings cannot be empty.
									|The previous value has been restored.';
									|en = 'General file storage settings cannot be empty.
									|The previous value has been restored.'; fa = 'General file storage settings cannot be empty.
									|The previous value has been restored.';
									|it = 'General file storage settings cannot be empty.
									|The previous value has been restored.';
									|pl = 'General file storage settings cannot be empty.
									|The previous value has been restored.';
									|tr = 'Genel dosya saklama ayarlarının değeri mutlaka doldurulmalıdır.
									|Eski değer geri yüklendi.'");
			ShowMessageBox(,MessageText);

		EndIf;
	EndIf;

	Return Result;	

EndFunction

&AtServerNoContext
Function GetDefaultSettingCurrentValue()

	Return InformationRegisters.FileArchiveSettings.GetStorageDaysCountFromDefaultSetting();

EndFunction

&AtServerNoContext
Function GetFilesTransferOperationsExecutionCurrentStatusPresentation(Val BackgroundJobIdentifier = Undefined)
	
	If Not Common.SubsystemExists("StandardSubsystems.ScheduledJobs") Then
		Return "";
	EndIf;

	RaiseIfNoAdministrationRights();

	InfoToGeneratePresentation = New Structure;
	InfoToGeneratePresentation.Insert("State"	, Undefined);
	InfoToGeneratePresentation.Insert("Begin"		, Date(1,1,1));
	InfoToGeneratePresentation.Insert("End"		, Date(1,1,1));	

	If BackgroundJobIdentifier = Undefined Then

		ScheduledJobMetadata1 = Metadata.ScheduledJobs.TransferFilesBetweenOperationalStorageAndArchive;

		Filter = New Structure;
		Filter.Insert("MethodName", ScheduledJobMetadata1.MethodName);
		Filter.Insert("State", BackgroundJobState.Active);
		FilesTransferBackgroundJobs = BackgroundJobs.GetBackgroundJobs(Filter);
		
		If FilesTransferBackgroundJobs.Count() > 0 Then
			FillPropertyValues(InfoToGeneratePresentation, FilesTransferBackgroundJobs[0]);
		Else

			Filter.Delete("State");

			FilesTransferBackgroundJobs = BackgroundJobs.GetBackgroundJobs(Filter);

			If FilesTransferBackgroundJobs.Count() > 0 Then
				LastBackgroundJob = FilesTransferBackgroundJobs[0];
				For Each BackgroundJob In FilesTransferBackgroundJobs Do
					If LastBackgroundJob.End < BackgroundJob.End Then
						LastBackgroundJob = BackgroundJob;
					EndIf;
				EndDo;

				FillPropertyValues(InfoToGeneratePresentation, LastBackgroundJob);
			EndIf;	
		EndIf;
	Else

		FoundBackgroundJob = BackgroundJobs.FindByUUID(BackgroundJobIdentifier);

		If FoundBackgroundJob <> Undefined Then

			FillPropertyValues(InfoToGeneratePresentation, FoundBackgroundJob);
		EndIf;
	EndIf;

	Return GetBackgroundJobExecutionStatusPresentation(InfoToGeneratePresentation);

EndFunction

&AtServerNoContext
Function GetBackgroundJobExecutionStatusPresentation(BackgroundJobStatusInfo)

	Result = "";

	If BackgroundJobStatusInfo.State = Undefined Then

		Result = NStr("ru = 'Нет информации';
						|vi = 'No info';
						|en = 'No info'; fa = 'No info';
						|it = 'No info';
						|pl = 'No info';
						|tr = 'Bilgi yok'");

	ElsIf BackgroundJobStatusInfo.State = BackgroundJobState.Active Then

		Result = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Выполняется. Начато %1';
																				|vi = 'In progress. Started at %1';
																				|en = 'In progress. Started at %1'; fa = 'In progress. Started at %1';
																				|it = 'In progress. Started at %1';
																				|pl = 'In progress. Started at %1';
																				|tr = 'İşleniyor. Başlatıldı %1'"), 
																			Format(BackgroundJobStatusInfo.Begin, "DLF=DT"));

	Else

		Result = StringFunctionsClientServer.SubstituteParametersToString("%1 %2", 
																			BackgroundJobStatusInfo.State, 
																			Format(BackgroundJobStatusInfo.End, "DLF=DT"));

	EndIf;

	Return Result;

EndFunction

&AtClient
Procedure CheckBackgroundJobExecution()
	If ValueIsFilled(BackgroundJobIdentifier) And Not IsJobCompleted(BackgroundJobIdentifier) Then
		AttachIdleHandler("CheckBackgroundJobExecution", 5, True);
	Else
		Items.LabelCurrentState.Title = GetFilesTransferOperationsExecutionCurrentStatusPresentation(BackgroundJobIdentifier);
		BackgroundJobIdentifier = "";
	EndIf;
EndProcedure

&AtServerNoContext
Function IsJobCompleted(Val BackgroundJobIdentifier)

	Result = True;
	
	JobCompletingResult = TimeConsumingOperations.JobCompleted(BackgroundJobIdentifier, True);
	
	If JobCompletingResult.Status = "Running" Then
		Result = False;
	EndIf;

	Return Result;
EndFunction

&AtServerNoContext
Procedure RaiseIfNoAdministrationRights(Val ModuleScheduledJobsInternal = Undefined)
	
	If ModuleScheduledJobsInternal = Undefined Then
		ModuleScheduledJobsInternal = Common.CommonModule("ScheduledJobsInternal");
	EndIf;
	
	ModuleScheduledJobsInternal.RaiseIfNoAdministrationRights();
	
EndProcedure

#EndRegion