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
	
	CreationDateComparisonOperator = "before";
	InitializeAdditionalConditions();
	FillPossibleOwnersList(Items.FilesOwner.ChoiceList);
	FilesOperationsInternal.FillListWithFilesTypes(Items.FilesExtensions.ChoiceList);
	
	StorageVolumesCount = StorageVolumesCount();
	StoreFilesInVolumesOnHardDrive = FilesOperationsInVolumesInternal.ShouldStoreFilesInVolumes();
	
	If Not StoreFilesInVolumesOnHardDrive
		And StorageVolumesCount > 0 Then
		
		Action = "MoveToInfobase";
		Items.Action.Enabled = False;
	Else
		Action = ?(StorageVolumesCount = 1, "MoveToVolumes", "MoveBetweenVolumes");
	EndIf;
	
	If Common.IsMobileClient() Then
		CommandBarLocation = FormCommandBarLabelLocation.Auto;
	EndIf;
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If StorageVolumesCount = 0 Then
		CallbackDescription = New CallbackDescription("WhenOpeningAfterClosingTheWarning", ThisObject);
		ShowMessageBox(CallbackDescription, NStr("vi = 'Không thể di chuyển tệp giữa các quyển, bởi vì không có quyển nào để sắp xếp tệp.';
												|ru = 'Невозможно перенести файлы между томами, т.к. нет ни одного тома для размещения файлов.';
												|en = 'Cannot move the files between volumes since there is no volume available for storing files.'; fa = 'Cannot move the files between volumes since there is no volume available for storing files.';
												|it = 'Impossibile trasferire i file tra i volumi perché non ci sono volumi in cui posizionare i file.';
												|pl = 'Przeniesienie plików między woluminami jest niemożliwe, ponieważ nie ma żadnego woluminu do umieszczenia plików.';
												|tr = 'Hacimler arasında dosya aktarımı mümkün değildir, çünkü dosyaları yerleştirecek bir hacim yok.'"));	
		Return;
	EndIf;
	
	FormItemsManagement();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ActionOnChange(Item)
	
	If Action = "MoveBetweenVolumes"
		And StorageVolumesCount = 1 Then
		
		Action = "MoveToVolumes";
		ShowMessageBox(, NStr("vi = 'Không thể chuyển tệp giữa các ổ: một ổ được chỉ định trong cài đặt để đặt tệp.';
								|ru = 'Невозможно перенести файлы между томами: в настройках указан один том для размещения файлов.';
								|en = 'Cannot move the files between volumes as only one file storage volume is defined in the settings.'; fa = 'Cannot move the files between volumes as only one file storage volume is defined in the settings.';
								|it = 'Impossibile spostare i file tra i volumi: nelle impostazioni è indicato solo un volume per allocazione dei file.';
								|pl = 'Niemożliwe jest przeniesienie plików między woluminami: w ustawieniach podano jeden wolumin do umieszczenia plików.';
								|tr = 'Birimler arasında dosya aktarımı yapılamıyor: Dosyaları barındırmak için ayarlarda bir hacim belirtilir.'"));
	EndIf;
	
	FormItemsManagement();
	
EndProcedure

&AtClient
Procedure DestinationStorageVolumeOnChange(Item)
	
	MoveToVolume = ValueIsFilled(DestinationStorageVolume);
	
EndProcedure

&AtClient
Procedure StorageVolumeSourceOnChange(Item)
	
	MoveFromVolume = ValueIsFilled(StorageVolumeSource);
	
EndProcedure

&AtClient
Procedure FilesOwnerOnChange(Item)
	
	MoveOwnerFiles = Not IsBlankString(FilesOwner);
	
EndProcedure

&AtClient
Procedure FilesExtensionsOnChange(Item)
	
	MoveByExtension = Not IsBlankString(FilesExtensions);
	
EndProcedure

&AtClient
Procedure FilesExtensionsChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	FilesExtensions = FilesOperationsInternalClient.ExtensionsByFileType(ValueSelected);
	MoveByExtension = True;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ExecuteTransfer(Command)
	
	If Action = "MoveBetweenVolumes" And Not ValueIsFilled(DestinationStorageVolume) Then
		CommonClient.MessageToUser(
			NStr("vi = 'khối lượng mà các tập tin sẽ được chuyển không đầy đủ.';
				|ru = 'Не заполнен том, в который будут перенесены файлы.';
				|en = 'Please specify the destination volume.'; fa = 'Please specify the destination volume.';
				|it = 'Il volume nel quale saranno spostati i file non è compilato.';
				|pl = 'Nie wypełniono woluminu, do którego zostaną przeniesione pliki.';
				|tr = 'Dosyaların aktarılacağı hacim dolu değil.'"), , "DestinationStorageVolume");
		Return;
	EndIf;
	
	TimeConsumingOperation = ExecuteTransferAtServer();
	CallbackOnCompletion = New CallbackDescription("ExecuteTransferCompletion", ThisObject);
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion);

EndProcedure

#EndRegion

#Region Private

// Parameters:
//  Result - See TimeConsumingOperationsClient.NewResultLongOperation
//  AdditionalParameters - Undefined
//
&AtClient
Procedure ExecuteTransferCompletion(Result, AdditionalParameters) Export

	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		StandardSubsystemsClient.OutputErrorInfo(
			Result.ErrorInfo);
		Return;
	EndIf;
		
	TransferResult = GetFromTempStorage(Result.ResultAddress); // See DataProcessors.FileTransfer.ExecuteFileTransfer
	If TransferResult.TransferErrors.Count() = 0 Then
		If TransferResult.FilesTransferred > 0 Then
			Explanation = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Đã hoàn tất quá trình chuyển tệp. Đã di chuyển %1 tệp.';
																						|ru = 'Завершен перенос файлов. Перенесено файлов %1.';
																						|en = 'The files are moved. Total files: %1.'; fa = 'The files are moved. Total files: %1.';
																						|it = 'Trasferimento file completato. File trasferiti %1.';
																						|pl = 'Zakończono przenoszenie plików. Przeniesiono plików %1.';
																						|tr = 'Dosya aktarımı tamamlandı. Aktarılan dosyalar%1.'"),
				Format(TransferResult.FilesTransferred, "NZ=0; NG="));
		Else
			Explanation = NStr("vi = 'Không có tệp nào phù hợp với các điều kiện đã đặt.';
								|ru = 'Нет ни одного файла, подходящего под заданные условия.';
								|en = 'There are no files matching the specified conditions.'; fa = 'There are no files matching the specified conditions.';
								|it = 'Non vi è alcun file adeguato alle condizioni indicate.';
								|pl = 'Nie ma ani jednego pliku, spełniającego zadane warunki.';
								|tr = 'Belirtilen koşullarla eşleşen dosya yok.'");
			If AdditionalConditions.Settings.Filter.Items.Count() > 1 Then
				Explanation = Explanation + Chars.LF + NStr("vi = 'Lưu ý rằng, các điều kiện bổ sung được hợp nhất bởi ""VÀ"", nếu chúng không được gom nhóm vào nhóm ""HOẶC"".';
															|ru = 'Обратите внимание, что дополнительные условия объединяются по ""И"", если они не сгруппированы в группу ""Или"".';
															|en = 'Consider that additional conditions are grouped by ""AND"" if they are not grouped into an ""Or"" group.'; fa = 'Consider that additional conditions are grouped by ""AND"" if they are not grouped into an ""Or"" group.';
															|it = 'Le condizioni aggiuntive vengono unite con ""And"" se non sono raggruppate nel gruppo ""Or"".';
															|pl = 'Zwróć uwagę, że dodatkowe warunki są grupowane za pomocą ""And"", jeśli nie są one grupowane do grupy ""Or"".';
															|tr = '""OR"" grubunda gruplandırılmamışlarsa, ek koşulların ""AND"" ile gruplandırıldığına dikkat ediniz.'");
			EndIf;
		EndIf;
		ShowMessageBox(, Explanation);
	Else
		Explanation = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đã chuyển: %1 tệp, không thể chuyển: %2';
				|ru = 'Перенесено файлов: %1, не удалось перенести: %2';
				|en = 'Moved files: %1, failed to move: %2'; fa = 'Moved files: %1, failed to move: %2';
				|it = 'File trasferiti: %1, non è stato possibile trasferire: %2';
				|pl = 'Przeniesiono plików: %1, nie udało się przenieść: %2';
				|tr = 'Aktarılan dosyalar: %1, aktarılamadı:%2'"),
			TransferResult.FilesTransferred, TransferResult.TransferErrors.Count());
		
		FormParameters = New Structure;
		FormParameters.Insert("Explanation", Explanation);
		FormParameters.Insert("FilesWithErrors", TransferResult.TransferErrors);
		OpenForm("DataProcessor.FileTransfer.Form.ReportForm", FormParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure FormItemsManagement()
	
	SourceAvailability = True;
	DestinationAvailability = True;
	
	If Action = "MoveBetweenVolumes" Then
		MoveToVolume = True;
	ElsIf Action = "MoveToVolumes" Then
		MoveFromVolume = False;
		StorageVolumeSource = Undefined;
		SourceAvailability = False;
	ElsIf Action = "MoveToInfobase" Then
		MoveToVolume = False;
		DestinationStorageVolume = Undefined;
		DestinationAvailability = False;
	EndIf;
	
	Items.MoveToVolume.Enabled = Not Action = "MoveBetweenVolumes";
	
	Items.SourceSettings.Enabled = SourceAvailability;
	Items.DestinationSettings.Enabled = DestinationAvailability;
	
EndProcedure

&AtClient
Procedure WhenOpeningAfterClosingTheWarning(Result) Export
	
	Close();
	
EndProcedure

&AtServer
Function ExecuteTransferAtServer()
	
	SelectCheckBoxesCorrectly();
	
	FileTransferOptions = DataProcessors.FileTransfer.FileTransferOptions();
	FileTransferOptions.Action = Action;
	FileTransferOptions.MoveToVolume = MoveToVolume;
	FileTransferOptions.DestinationStorageVolume = DestinationStorageVolume;
	
	ExecutionParameters = TimeConsumingOperations.FunctionExecutionParameters(UUID);
	
	Return TimeConsumingOperations.ExecuteFunction(ExecutionParameters, "DataProcessors.FileTransfer.ExecuteFileTransfer",
		FilesToTransfer(), FileTransferOptions);
	
EndFunction

&AtServer
Procedure InitializeAdditionalConditions()
	
	CompositionSchema = CompositionSchema();
	CompositionSchemaAddress = PutToTempStorage(
		CompositionSchema, UUID); // DataCompositionSchema
	AdditionalConditions.Initialize(
		New DataCompositionAvailableSettingsSource(CompositionSchemaAddress));
	AdditionalConditions.LoadSettings(CompositionSchema.DefaultSettings);
	AdditionalConditions.Refresh();
	
EndProcedure

&AtServer
Procedure SelectCheckBoxesCorrectly()
	
	If Not ValueIsFilled(DestinationStorageVolume) Then
		MoveToVolume = False;
	EndIf;
	
	If Not ValueIsFilled(StorageVolumeSource) Then
		MoveFromVolume = False;
	EndIf;
	
	If Not ValueIsFilled(CreationDate) Then
		MoveByCreationDate = False;
	EndIf;
	
	If IsBlankString(FilesExtensions) Then
		MoveByExtension = False;
	EndIf;
	
EndProcedure

&AtServer
Function FilesToTransfer()
	
	DataCompositionSchema = CompositionSchema(False,
		?(MoveOwnerFiles And Not IsBlankString(FilesOwner), FilesOwner, ""));
	
	SettingsComposer = New DataCompositionSettingsComposer;
	SettingsComposer.LoadSettings(AdditionalConditions.Settings);
	
	FilterByAction = ?(Action = "MoveToVolumes",
		Enums.FileStorageTypes.InInfobase,
		Enums.FileStorageTypes.InVolumesOnHardDrive);
	
	AddFilterSetting(SettingsComposer, "FileStorageType",
		DataCompositionComparisonType.Equal, FilterByAction);
	
	If MoveToVolume Then
		AddFilterSetting(SettingsComposer, "Volume",
			DataCompositionComparisonType.NotEqual, DestinationStorageVolume);
	EndIf;
		
	If MoveFromVolume Then
		AddFilterSetting(SettingsComposer, "Volume",
			DataCompositionComparisonType.Equal, StorageVolumeSource);
	EndIf;
	
	If MoveByCreationDate Then
		
		AddFilterSetting(SettingsComposer, "CreationDate",
			?(CreationDateComparisonOperator = "before", DataCompositionComparisonType.LessOrEqual,
			DataCompositionComparisonType.GreaterOrEqual), CreationDate);
	EndIf;
	
	If MoveByExtension Then
		
		FilterByExtension = StringFunctionsClientServer.SplitStringIntoSubstringsArray(
			FilesExtensions, " ", True, True);
			
		For Each Extension In FilterByExtension Do
			Extension = Lower(Extension);
		EndDo;
		
		AddFilterSetting(SettingsComposer, "Extension",
			DataCompositionComparisonType.InList, FilterByExtension);
		
	EndIf;
	
	TemplateComposer = New DataCompositionTemplateComposer;
	DataCompositionTemplate = TemplateComposer.Execute(DataCompositionSchema,
		SettingsComposer.Settings, , , Type("DataCompositionValueCollectionTemplateGenerator"));
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(DataCompositionTemplate);
	
	FilesToTransfer = New ValueTable;
	
	OutputProcessor = New DataCompositionResultValueCollectionOutputProcessor;
	OutputProcessor.SetObject(FilesToTransfer);
	OutputProcessor.Output(CompositionProcessor);
	
	Return FilesToTransfer;
	
EndFunction

&AtServerNoContext
Function CompositionSchema(FilesCatalogsOnly = True, FilesOwner = "")
	
	If FilesCatalogsOnly Then
		QueryText = "";
	Else
		
		If Not IsBlankString(FilesOwner) Then
			SeparatorPosition = StrFind(FilesOwner, ".");
			OwnerTypeAsString = Left(FilesOwner, SeparatorPosition - 1)
				+ "Ref" + Mid(FilesOwner, SeparatorPosition);
		EndIf;
		
		QueryText = 
		"SELECT
		|	FilesVersions.Ref AS Ref,
		|	FilesVersions.Description AS Description,
		|	FilesVersions.DeletionMark AS DeletionMark,
		|	FilesVersions.Author AS Author,
		|	FilesVersions.Owner.FileOwner AS FileOwner,
		|	FilesVersions.CreationDate AS CreationDate,
		|	&IsInternal AS IsInternal,
		|	FilesVersions.Owner.ChangedBy AS ChangedBy,
		|	FilesVersions.Size AS Size,
		|	FilesVersions.Extension AS Extension,
		|	FilesVersions.Volume AS Volume,
		|	FilesVersions.Owner.StoreVersions AS StoreVersions,
		|	FilesVersions.FileStorageType AS FileStorageType,
		|	FilesVersions.TextExtractionStatus AS TextExtractionStatus
		|FROM
		|	Catalog.FilesVersions AS FilesVersions";
		
		FilterByOwnerSet = IsBlankString(FilesOwner);
		VersionsOwnersMetadataTypes = Metadata.Catalogs.FilesVersions.StandardAttributes.Owner.Type;
		For Each MetadataType In VersionsOwnersMetadataTypes.Types() Do
			
			OwnerMetadata = Metadata.FindByType(MetadataType);
			If OwnerMetadata.Attributes.Find("IsInternal") <> Undefined Then
				
				QueryText = StrReplace(QueryText, "&IsInternal", "ISNULL(FilesVersions.Owner.IsInternal, FALSE)");
				If FilterByOwnerSet Then
					Break;
				EndIf;
				
			EndIf;
			
			If Not FilterByOwnerSet
				And OwnerMetadata.Attributes.FileOwner.Type.ContainsType(Type(OwnerTypeAsString)) Then
				
				FilterByOwnerSet = True;
				AdditionalCondition = "
					|WHERE
					|	FilesVersions.Owner.FileOwner REFS Catalog.Files"; // @query-part
				AdditionalCondition = StrReplace(AdditionalCondition, "Catalog.Files", FilesOwner);
				QueryText = QueryText + AdditionalCondition;
				
			EndIf;
			
		EndDo;
		
		If Not IsBlankString(FilesOwner)
			And Not FilterByOwnerSet Then
			QueryText = "";
		Else
			QueryText = StrReplace(QueryText, "&IsInternal", "FALSE");
		EndIf;
		
	EndIf;
	
	SubqueryText =
	"SELECT
	|	CatalogFiles_.Ref,
	|	CatalogFiles_.Description,
	|	CatalogFiles_.DeletionMark,
	|	CatalogFiles_.Author,
	|	CatalogFiles_.FileOwner,
	|	CatalogFiles_.CreationDate,
	|	&IsInternal,
	|	CatalogFiles_.ChangedBy,
	|	CatalogFiles_.Size,
	|	CatalogFiles_.Extension,
	|	CatalogFiles_.Volume,
	|	CatalogFiles_.StoreVersions,
	|	CatalogFiles_.FileStorageType,
	|	CatalogFiles_.TextExtractionStatus
	|FROM
	|	&TableOfFiles AS CatalogFiles_";
	
	If Not IsBlankString(FilesOwner) Then
		
		SubqueryText = SubqueryText + "
			|WHERE
			|	CatalogFiles_.FileOwner Ref " + FilesOwner;
		
	EndIf;
	
	AttachedFilesTypes = Metadata.DefinedTypes.AttachedFile.Type.Types();
	For Each FileType In AttachedFilesTypes Do
		
		If FileType = Type("CatalogRef.FilesVersions")
			Or FileType = Type("CatalogRef.MetadataObjectIDs")
			Or (Not FilesCatalogsOnly
			And VersionsOwnersMetadataTypes.ContainsType(FileType)) Then
			
			Continue;
		EndIf;
		
		MetadataObject = Metadata.FindByType(FileType);
		If Not IsBlankString(FilesOwner) Then
			
			SeparatorPosition = StrFind(FilesOwner, ".");
			OwnerTypeAsString = Left(FilesOwner, SeparatorPosition - 1)
				+ "Ref" + Mid(FilesOwner, SeparatorPosition);
				
			If Not MetadataObject.Attributes.FileOwner.Type.ContainsType(Type(OwnerTypeAsString)) Then
				Continue;
			EndIf;
			
		EndIf;
		
		OwnerQueryText = StrReplace(SubqueryText, "&TableOfFiles", MetadataObject.FullName());
		OwnerQueryText = StrReplace(OwnerQueryText, "&IsInternal", 
			?(MetadataObject.Attributes.Find("IsInternal") <> Undefined, "CatalogFiles_.IsInternal", "FALSE"));
		
		If MetadataObject.Attributes.Find("FileOwner") = Undefined Then
			Raise "";
		EndIf;
		
		QueryText = QueryText
			+ ?(IsBlankString(QueryText), "", "
			|
			|UNION ALL
			|
			|") + OwnerQueryText;
		
	EndDo;
	
	CompositionSchema = New DataCompositionSchema;
	
	DataSource = CompositionSchema.DataSources.Add();
	DataSource.Name = "FilesDataSource";
	DataSource.DataSourceType = "Local";
	
	DataSet = CompositionSchema.DataSets.Add(Type("DataCompositionSchemaDataSetQuery"));
	DataSet.Name = "DataSetFiles";
	DataSet.Query = QueryText;
	DataSet.DataSource = DataSource.Name;
	
	CompositionGroup1 = CompositionSchema.DefaultSettings.Structure.Add(Type("DataCompositionGroup"));
	
	GroupingField = CompositionGroup1.GroupFields.Items.Add(Type("DataCompositionGroupField"));
	GroupingField.Field = New DataCompositionField("Ref");
	
	CompositionGroup1.Selection.Items.Add(Type("DataCompositionAutoSelectedField"));
	
	CompositionSchema.TotalFields.Clear();
	
	Return CompositionSchema;
	
EndFunction

&AtServerNoContext
Function StorageVolumesCount()
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	TRUE AS TrueValue
	|FROM
	|	Catalog.FileStorageVolumes AS FileStorageVolumes
	|WHERE
	|	FileStorageVolumes.DeletionMark = FALSE";
	
	Return Query.Execute().Unload().Count();
	
EndFunction

&AtServerNoContext
Procedure AddFilterSetting(SettingsComposer, FieldName, Var_ComparisonType, Value)
	
	Filter = SettingsComposer.Settings.Filter.Items.Add(Type("DataCompositionFilterItem"));
	Filter.LeftValue = New DataCompositionField(FieldName);
	Filter.ComparisonType = Var_ComparisonType;
	Filter.RightValue = Value;
	Filter.Use = True;
	
EndProcedure

&AtServerNoContext
Procedure FillPossibleOwnersList(FilesOwners)
	
	OwnersTypes = Metadata.DefinedTypes.AttachedFilesOwner.Type.Types();
	For Each OwnerType In OwnersTypes Do
		
		If OwnerType = Type("CatalogRef.MetadataObjectIDs") Then
			Continue;
		EndIf;
		
		MetadataObject = Metadata.FindByType(OwnerType);
		FilesOwners.Add(MetadataObject.FullName(), MetadataObject.Synonym);
		
	EndDo;
	
	FilesOwners.SortByPresentation();
	
EndProcedure

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
