///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

// If the "FileOperations" subsystem is not integrated, delete the form from the configuration.
// 

#Region Variables

&AtClient
Var RefreshInterface;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	AreBinaryDataStoragesAvailable = FileArchiveManagementServer.AreBinaryDataStoragesAvailable();

	FilesStorageMethodConfigureChoiceList();

	MaxFileSize = FilesOperations.MaxFileSizeCommon() / (1024*1024);
	MaxDataAreaFileSize = FilesOperations.MaxFileSize() / (1024*1024);
	
	DataSeparationEnabled = Common.DataSeparationEnabled();
	If DataSeparationEnabled Then
		Items.MaxFileSize.MaxValue = MaxFileSize;
	EndIf;
	
	DenyUploadFilesByExtension = ConstantsSet.DenyUploadFilesByExtension;
	
	ParametersOfFilesStorageInIB = FilesOperationsInVolumesInternal.FilesStorageParametersInInfobase();
	If ParametersOfFilesStorageInIB <> Undefined Then
		IBFilesExtensions = ParametersOfFilesStorageInIB.FilesExtensions;
		MaxFileSizeInIB = ParametersOfFilesStorageInIB.MaximumSize / (1024*1024);
	EndIf;
	
	FilesOperationsInternal.FillListWithFilesTypes(Items.IBFilesExtensions.ChoiceList);
	
	IsSystemAdministrator = Users.IsFullUser(, True);
	Items.FilesStorageManagement.Visible = IsSystemAdministrator;
	Items.FilesVolumesManagementGroup.Visible = IsSystemAdministrator;
	Items.FilesSizeManagementInIBGroup.Visible = IsSystemAdministrator;
	Items.CommonParametersForAllDataAreas.Visible = IsSystemAdministrator And DataSeparationEnabled;
	Items.TextFilesExtensionsListGroup.Visible = Not DataSeparationEnabled;
	Items.IBFilesExtensionsManagementGroup.Visible = IsSystemAdministrator;
	
	If IsSystemAdministrator Then
		Items.GroupDeduplication.Visible = ConstantsSet.FilesStorageMethod <> "InVolumesOnHardDrive" And Not IsDeduplicationCompleted();
		FilesStorageMethodValue = ConstantsSet.FilesStorageMethod;
		ConfigureSettingsOfStorageInVolumesAvailability();
		UseFileArchive = ConstantsSet.UseFileArchive;
	Else
		Items.GroupDeduplication.Visible = False;
	EndIf;

	IsFileArchiveUsageAvailable = IsSystemAdministrator And FileArchiveManagementServer.IsFileArchiveAvailable();
	Items.GroupFileArchive.Visible = IsFileArchiveUsageAvailable;
	If IsFileArchiveUsageAvailable Then
		SetFileArchiveManagementSettingsAvailability();
	EndIf;

	SetAvailability();
	
	ApplicationSettingsOverridable.FilesOperationSettingsOnCreateAtServer(ThisObject);
	
	If Common.IsMobileClient() Then
		
		Items.IndentFilesSizeInIB.Visible = False;
		Items.IndentIBFilesExtensions.Visible = False;
		Items.MaxFileSizeInIB.SpinButton = False;
		Items.IBFilesExtensions.TitleLocation = FormItemTitleLocation.Top;
		Items.TextFilesExtensionsList.TitleLocation = FormItemTitleLocation.Top;
		Items.FilesExtensionsListDocumentDataAreas.TitleLocation = FormItemTitleLocation.Top;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Not Exit Then
		RefreshApplicationInterface();
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	If EventName = "Write_ConstantsSet" And Source = "AllowAccessToInternetServices" Then
		SetAvailability("AllowAccessToInternetServices");
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FilesStorageMethodOnChange(Item)

	If ConstantsSet.FilesStorageMethod = FilesStorageMethodValue Then
		Return;
	EndIf;
	
	ConstantsSet.StoreFilesInVolumesOnHardDrive = IsFilesStorageMethodOnDisk(ConstantsSet.FilesStorageMethod);

	NotificationProcessing = New CallbackDescription(
		"FilesStorageMethodOnChangeCompletion", ThisObject, Item);

	If IsFilesStorageMethodOnDisk(FilesStorageMethodValue)
		And ConstantsSet.StoreFilesInVolumesOnHardDrive Then
		
		RunCallback(NotificationProcessing, DialogReturnCode.OK);
		Return;
	EndIf;

	Try

		RequestsForPermissionToUseExternalResources = PermissionRequestsToUseExternalResourcesOfFilesStorageVolumes(
			ConstantsSet.StoreFilesInVolumesOnHardDrive);

		If CommonClient.SubsystemExists("StandardSubsystems.SecurityProfiles") Then
			ModuleSafeModeManagerClient = CommonClient.CommonModule("SafeModeManagerClient");
			ModuleSafeModeManagerClient.ApplyExternalResourceRequests(
				RequestsForPermissionToUseExternalResources, ThisObject, NotificationProcessing);
		Else
			RunCallback(NotificationProcessing, DialogReturnCode.OK);
		EndIf;

	Except

		ConstantsSet.FilesStorageMethod = FilesStorageMethodValue;
		ConstantsSet.StoreFilesInVolumesOnHardDrive = IsFilesStorageMethodOnDisk(FilesStorageMethodValue);
		Raise;

	EndTry;		
	
EndProcedure

&AtClient
Procedure CreateSubdirectoriesWithOwnersNamesOnChange(Item)
	
	Attachable_OnChangeAttribute(Item);
	
EndProcedure

&AtClient
Procedure IBFilesExtensionsOnChange(Item)
	
	OnChangeSettingsOfFilesStorageInIB();
	
EndProcedure

&AtClient
Procedure IBFilesExtensionsChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	IBFilesExtensions = FilesOperationsInternalClient.ExtensionsByFileType(ValueSelected);
	OnChangeSettingsOfFilesStorageInIB();
	
EndProcedure

&AtClient
Procedure MaxFileSizeInIBOnChange(Item)
	
	OnChangeSettingsOfFilesStorageInIB();
	
EndProcedure

&AtClient
Procedure DenyUploadFilesByExtensionOnChange(Item)
	
	If Not DenyUploadFilesByExtension Then
		
		Notification = New CallbackDescription(
			"ProhibitFilesImportByExtensionAfterConfirm", ThisObject, New Structure("Item", Item));
		UsersInternalClient.ShowSecurityWarning(Notification,
			UsersInternalClientServer.SecurityWarningKinds().OnChangeDeniedExtensionsList);
		Return;
		
	EndIf;
	
	Attachable_OnChangeAttribute(Item);
	
EndProcedure

&AtClient
Procedure SynchronizeFilesOnChange(Item)
	
	Attachable_OnChangeAttribute(Item);
	
EndProcedure

&AtClient
Procedure DeniedDataAreaExtensionsListOnChange(Item)
	
	Attachable_OnChangeAttribute(Item);
	
EndProcedure

&AtClient
Procedure MaxDataAreaFileSizeOnChange(Item)
	
	If MaxDataAreaFileSize = 0 Then
		
		MessageText = NStr("vi = 'Chưa điền trường ""Dung lượng tối đa của tệp"".';
							|ru = 'Поле ""Максимальный размер файла"" не заполнено.';
							|en = 'File size limit is required.'; fa = 'File size limit is required.';
							|it = 'Il campo ""Dimensione massima file"" non è compilato.';
							|pl = 'Pole ""maksymalny rozmiar pliku"" nie jest wypełnione.';
							|tr = '""Maksimum dosya boyutu"" alanı doldurulmadı.'");
		CommonClient.MessageToUser(MessageText, ,"MaxDataAreaFileSize");
		Return;
		
	EndIf;
	
	Attachable_OnChangeAttribute(Item);
	
EndProcedure

&AtClient
Procedure FilesExtensionsListDocumentDataAreasOnChange(Item)
	
	Attachable_OnChangeAttribute(Item);
	
EndProcedure

&AtClient
Procedure TextFilesExtensionsListOnChange(Item)
	
	Attachable_OnChangeAttribute(Item);
	
EndProcedure

#Region CommonParametersForAllDataAreas

&AtClient
Procedure MaxFileSizeOnChange(Item)
	
	If MaxFileSize = 0 Then
		
		MessageText = NStr("vi = 'Chưa điền trường ""Dung lượng tối đa của tệp"".';
							|ru = 'Поле ""Максимальный размер файла"" не заполнено.';
							|en = 'File size limit is required.'; fa = 'File size limit is required.';
							|it = 'Il campo ""Dimensione massima file"" non è compilato.';
							|pl = 'Pole ""maksymalny rozmiar pliku"" nie jest wypełnione.';
							|tr = '""Maksimum dosya boyutu"" alanı doldurulmadı.'");
		CommonClient.MessageToUser(MessageText, ,"MaxFileSize");
		Return;
		
	EndIf;
	
	Attachable_OnChangeAttribute(Item);
	
EndProcedure

&AtClient
Procedure DeniedExtensionsListOnChange(Item)
	
	Attachable_OnChangeAttribute(Item);
	
EndProcedure

&AtClient
Procedure FilesExtensionsListOpenDocumentOnChange(Item)
	
	Attachable_OnChangeAttribute(Item);
	
EndProcedure

#EndRegion

#Region FileArchiveOperationsParameters

&AtClient
Procedure UseFileArchiveOnChange(Item)

	Attachable_OnChangeAttribute(Item);

EndProcedure

&AtClient
Procedure NotificationAboutFileUnavailabilityInTheArchiveOnChange(Item)

	Attachable_OnChangeAttribute(Item);

EndProcedure

#EndRegion

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CatalogFiles(Command)
	
	OpenForm("Catalog.Files.ListForm", , ThisObject);
	
EndProcedure

&AtClient
Procedure CatalogFileStorageVolumes(Command)

	StorageVolumeType = CommonClient.PredefinedItem("Enum.StorageKinds.OperationalStorage");
	OpenFilesStorageVolumeCatalogListFormWithFilterByFilesStorageVolumeType(ThisObject, StorageVolumeType);

EndProcedure

&AtClient
Procedure FilesSynchronizationSetup(Command)
	
	OpenForm("InformationRegister.FileSynchronizationSettings.ListForm", , ThisObject);
	
EndProcedure

&AtClient
Procedure FileTransfer(Command)
	
	FilesOperationsInternalClient.MoveFiles();
	
EndProcedure

&AtClient
Async Procedure StartDeduplication(Command)
	
	QuestionTitle = NStr("vi = 'Loại bỏ trùng lặp tệp';
						|ru = 'Дедупликация файлов';
						|en = 'File deduplication'; fa = 'حذف تکرار فایل';
						|it = 'Дедупликация файлов';
						|pl = 'File deduplication';
						|tr = 'Dosya tekilleştirme'");
	QuestionTemplate = NStr("vi = 'Việc loại bỏ trùng lặp tệp cho phép tiết kiệm tới 30% dung lượng trong cơ sở thông tin bằng cách loại bỏ các tệp trùng lặp mà được lưu trữ trong ứng dụng (tùy chọn lưu trữ ""Trong cơ sở thông tin""). Việc loại bỏ trùng lặp các tệp hiện có mất từ ​​​​vài phút đến vài giờ, tùy thuộc vào dung lượng tệp trong ứng dụng. Nó có thể bị gián đoạn bất cứ lúc nào và được tiếp tục lại sau đó vào thời điểm thích hợp hơn. Trong trường hợp này, sẽ tự động lưu lại tất cả các tệp mới được thêm trong ứng dụng chỉ trong một bản sao.
	 |
	 |Trong quá trình loại bỏ trùng lặp các tệp, dung lượng cơ sở thông tin có thể tăng lên đáng kể. Do đó, trước khi bắt đầu, bạn nên:
	 |• đảm bảo có đủ dung lượng trống trên thiết bị chứa cơ sở thông tin (cần ít nhất %1 Mb);
	 |• tạo một bản sao lưu của cơ sở thông tin. 
	 |
	 |Sau khi hoàn tất, hãy nén cơ sở thông tin để quá trình loại bỏ trùng lặp tệp có hiệu lực.
	 |
	 |Bắt đầu loại bỏ trùng lặp tệp?';
	 |ru = 'Дедупликация файлов позволяет экономить до 30%% места в информационной базе за счет устранения дублей файлов, хранящихся в приложении (вариант хранения ""В информационной базе""). Дедупликация имеющихся файлов занимает от нескольких минут до нескольких часов в зависимости от объема файлов в приложении. В любой момент ее можно будет прервать и возобновить позднее в более подходящий момент времени. При этом все вновь добавляемые файлы уже автоматически сохраняются в приложении только в одном экземпляре.
	 |
	 |Во время дедупликации файлов размер информационной базы может существенно вырасти. Поэтому перед запуском рекомендуется:
	 |• убедиться, что имеется достаточно свободного места на устройстве, где размещается информационная база (требуется не менее %1 Мб);
	 |• сделать резервную копию информационной базы.
	 |
	 |После завершения выполнить сжатие информационной базы, чтобы дедупликация файлов вступила в силу.
	 |
	 |Запустить дедупликацию файлов?';
	 |en = 'With file deduplication, you can save up to 30% of infobase space by removing duplicate files stored in the application (the ""Infobase"" storage option). The process takes from minutes to hours, depending on the number of files, and can be paused and resumed at any time. All newly added files are automatically stored as a single instance.
	 |
	 |During deduplication, the infobase size may increase significantly. Therefore, before initiating the process, ensure that the device hosting the infobase has at least %1 MB of free space and back up the infobase. After completion, compress the infobase for the deduplication to take effect.
	 |
	 |Do you want to start file deduplication?'; fa = 'With file deduplication, you can save up to 30% of infobase space by removing duplicate files stored in the application (the ""Infobase"" storage option). The process takes from minutes to hours, depending on the number of files, and can be paused and resumed at any time. All newly added files are automatically stored as a single instance.
	 |
	 |During deduplication, the infobase size may increase significantly. Therefore, before initiating the process, ensure that the device hosting the infobase has at least %1 MB of free space and back up the infobase. After completion, compress the infobase for the deduplication to take effect.
	 |
	 |Do you want to start file deduplication?';
	 |it = 'Дедупликация файлов позволяет экономить до 30%% места в информационной базе за счет устранения дублей файлов, хранящихся в приложении (вариант хранения ""В информационной базе""). Дедупликация имеющихся файлов занимает от нескольких минут до нескольких часов в зависимости от объема файлов в приложении. В любой момент ее можно будет прервать и возобновить позднее в более подходящий момент времени. При этом все вновь добавляемые файлы уже автоматически сохраняются в приложении только в одном экземпляре.
	 |
	 |Во время дедупликации файлов размер информационной базы может существенно вырасти. Поэтому перед запуском рекомендуется:
	 |• убедиться, что имеется достаточно свободного места на устройстве, где размещается информационная база (требуется не менее %1 Мб);
	 |• сделать резервную копию информационной базы.
	 |
	 |После завершения выполнить сжатие информационной базы, чтобы дедупликация файлов вступила в силу.
	 |
	 |Запустить дедупликацию файлов?';
	 |pl = 'With file deduplication, you can save up to 30% of infobase space by removing duplicate files stored in the application (the ""Infobase"" storage option). The process takes from minutes to hours, depending on the number of files, and can be paused and resumed at any time. All newly added files are automatically stored as a single instance.
	 |
	 |During deduplication, the infobase size may increase significantly. Therefore, before initiating the process, ensure that the device hosting the infobase has at least %1 MB of free space and back up the infobase. After completion, compress the infobase for the deduplication to take effect.
	 |
	 |Do you want to start file deduplication?';
	 |tr = 'Dosya tekilleştirme, uygulamada depolanan yinelenen dosyaları ortadan kaldırarak bilgi tabanında %30''a kadar alan tasarrufu sağlar (""Bilgi tabanında"" depolama seçeneği). Mevcut dosyaların tekilleştirilmesi, uygulamadaki dosyaların boyutuna bağlı olarak birkaç dakikadan birkaç saate kadar sürebilir. Herhangi bir zamanda kesintiye uğratılabilir ve daha sonra daha uygun bir zamanda yeniden başlatılabilir. Bu durumda, yeni eklenen tüm dosyalar uygulamaya otomatik olarak tek bir kopya halinde kaydedilir.
	 |
	 |Dosya tekilleştirme sırasında bilgi tabanının boyutu önemli ölçüde büyüyebilir. Bu nedenle, başlamadan önce şunları yapmanız önerilir:
	 |• bilgi tabanının bulunduğu cihazda yeterli boş alan olduğundan emin olun (en az %1 MB gereklidir);
	 |• bilgi tabanının yedek bir kopyasını oluşturun. 
	 |
	 |Tamamlandıktan sonra, dosya tekilleştirme işleminin etkili olması için bilgi tabanını sıkıştırın.
	 |
	 |Dosya tekilleştirme başlatılsın mı?'");
	QueryText = StringFunctionsClientServer.SubstituteParametersToString(QuestionTemplate, FilesSizeInInfobase());
	Response = Await DoQueryBoxAsync(QueryText, QuestionDialogMode.YesNo, , DialogReturnCode.No, QuestionTitle);
	If Response <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	TimeConsumingOperation = StartDeduplicationAtServer();
	CallbackOnCompletion = New CallbackDescription("FinishDeduplication", ThisObject);
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	IdleParameters.Title = NStr("vi = 'Đang thực hiện loại bỏ trùng lặp tệp';
								|ru = 'Выполняется дедупликация файлов';
								|en = 'Deduplicating files'; fa = 'Deduplicating files';
								|it = 'Выполняется дедупликация файлов';
								|pl = 'Deduplicating files';
								|tr = 'Dosya tekilleştirmesi yapılıyor'");
	IdleParameters.OutputProgressBar = True;
	IdleParameters.CancelButtonTitle = NStr("vi = 'Ngừng';
											|ru = 'Прервать';
											|en = 'Cancel'; fa = 'انصراف';
											|it = 'Прервать';
											|pl = 'Cancel';
											|tr = 'Durdur'");
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
		
EndProcedure

&AtClient
Procedure FilesStorageVolumesCatalogArchiveItems(Command)

	StorageVolumeType = CommonClient.PredefinedItem("Enum.StorageKinds.ArchivalStorage");
	OpenFilesStorageVolumeCatalogListFormWithFilterByFilesStorageVolumeType(ThisObject, StorageVolumeType);

EndProcedure

&AtClient
Procedure FileArchiveOperationsSetting(Command)

	FormParameters = New Structure;
	FormParameters.Insert("IsOpeningFormAllowed", True);
	
	OpenForm("InformationRegister.FileArchiveSettings.ListForm", FormParameters, ThisObject);

EndProcedure
#EndRegion

#Region Private

&AtClient
Procedure FilesStorageMethodOnChangeCompletion(Response, Item) Export

	If Response <> DialogReturnCode.OK Then
		ConstantsSet.FilesStorageMethod = FilesStorageMethodValue;
		ConstantsSet.StoreFilesInVolumesOnHardDrive = IsFilesStorageMethodOnDisk(FilesStorageMethodValue);
		Return;
	EndIf;

	ShouldChangeStoredDataComposition = False;
	
	If Not AreBinaryDataStoragesAvailable Then
		If FilesStorageMethodValue = "InInfobase"
			And ConstantsSet.StoreFilesInVolumesOnHardDrive
			And Not HasFileStorageVolumes("InVolumesOnHardDrive") Then
			
			ShowMessageBox(, NStr("vi = 'Đã bật sử dụng lưu tệp trong các quyển trên file-server, nhưng còn chưa tùy chỉnh quyển.
				|Sẽ lưu lại các tệp được thêm trong cơ sở thông tin cho đến khi đã tùy chỉnh xong ít nhất một quyển lưu tệp.';
				|ru = 'Включено хранение файлов в томах на файловом сервере, но тома еще не настроены.
				|Добавляемые файлы будут сохраняться в информационной базе до тех пор, пока не будет настроен хотя бы один том хранения файлов.';
				|en = 'Storing files to the file server is enabled but the volumes are not configured.
				|Files will be saved to the infobase until at least one file storage volume is configured.'; fa = 'Storing files to the file server is enabled but the volumes are not configured.
				|Files will be saved to the infobase until at least one file storage volume is configured.';
				|it = 'Включено хранение файлов в томах на файловом сервере, но тома еще не настроены.
				|Добавляемые файлы будут сохраняться в информационной базе до тех пор, пока не будет настроен хотя бы один том хранения файлов.';
				|pl = 'Storing files to the file server is enabled but the volumes are not configured.
				|Files will be saved to the infobase until at least one file storage volume is configured.';
				|tr = 'Dosyaların dosya sunucusundaki birimlerde saklanması etkinleştirildi, ancak birimler henüz yapılandırılmadı.
				|Eklenen dosyalar, en az bir dosya depolama birimi yapılandırılana kadar bilgi tabanında saklanacak.'"));
		EndIf;
	Else

		ShouldChangeStoredDataComposition = True;

		If FileArchiveManagementClientServer.StorageMethodUsesVolumes(ConstantsSet.FilesStorageMethod) Then
			If Not HasFileStorageVolumes(ConstantsSet.FilesStorageMethod) Then
				WarningText = GetWarningTextByFilesStorageMethod(ConstantsSet.FilesStorageMethod);
				ShowMessageBox(, NStr("ru = '" + WarningText + "'"));
			EndIf;
		EndIf;				
	EndIf;
		
	OnChangeFilesStorageMethodAtServer(ShouldChangeStoredDataComposition);
	RefreshReusableValues();
	AfterChangeAttribute("FilesStorageMethod", False);
	AfterChangeAttribute("StoreFilesInVolumesOnHardDrive");
	
EndProcedure

// Parameters:
//  Result - Undefined
//            - String
//  AdditionalParameters - Structure:
//    * Item - FormField
//              - FormFieldExtensionForACheckBoxField
//
&AtClient
Procedure ProhibitFilesImportByExtensionAfterConfirm(Result, AdditionalParameters) Export
	
	If Result <> Undefined
		And Result = "Continue" Then
		
		Attachable_OnChangeAttribute(AdditionalParameters.Item);
	Else
		DenyUploadFilesByExtension = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnChangeSettingsOfFilesStorageInIB()
	
	SetParametersOfFilesStorageInIB(
		New Structure("FilesExtensions, MaximumSize",
		IBFilesExtensions, MaxFileSizeInIB*1024*1024));
	
	RefreshReusableValues();
	AfterChangeAttribute("ParametersOfFilesStorageInIB", False);
	
EndProcedure

&AtClient
Procedure Attachable_OnChangeAttribute(Item, ShouldRefreshInterface = True)
	
	ConstantName = OnChangeAttributeServer(Item.Name);
	RefreshReusableValues();
	AfterChangeAttribute(ConstantName, ShouldRefreshInterface);
	
EndProcedure

&AtClient
Procedure AfterChangeAttribute(ConstantName, ShouldRefreshInterface = True)
	
	If ShouldRefreshInterface Then
		RefreshInterface = True;
		AttachIdleHandler("RefreshApplicationInterface", 2, True);
	EndIf;
	
	If ConstantName <> "" Then
		Notify("Write_ConstantsSet", New Structure, ConstantName);
	EndIf;
	
EndProcedure

&AtClient
Procedure RefreshApplicationInterface()
	
	If RefreshInterface = True Then
		RefreshInterface = False;
		CommonClient.RefreshApplicationInterface();
	EndIf;
	
EndProcedure

&AtServer
Function OnChangeAttributeServer(TagName)
	
	DataPathAttribute = Items[TagName].DataPath;
	ConstantName = SaveAttributeValue(DataPathAttribute);
	
	SetAvailability(DataPathAttribute);
	RefreshReusableValues();
	
	Return ConstantName;
	
EndFunction

&AtServer
Procedure OnChangeFilesStorageMethodAtServer(Val ShouldChangeStoredDataComposition = False)

	BeginTransaction();
	Try
		Constants.FilesStorageMethod.Set(ConstantsSet.FilesStorageMethod);
		Constants.StoreFilesInVolumesOnHardDrive.Set(ConstantsSet.StoreFilesInVolumesOnHardDrive);
		
		If ShouldChangeStoredDataComposition Then
			ChangeStoredDataComposition(ConstantsSet.FilesStorageMethod);
		EndIf;
		CommitTransaction();
	Except
		RollbackTransaction();
		ConstantsSet.FilesStorageMethod		= FilesStorageMethodValue;
		ConstantsSet.StoreFilesInVolumesOnHardDrive = FilesOperationsClientServer.ShouldStoreFilesInVolumes(FilesStorageMethodValue);

		Raise;		
	EndTry;
	
	FilesStorageMethodValue = ConstantsSet.FilesStorageMethod;
	SetAvailability("ConstantsSet.FilesStorageMethod");
	RefreshReusableValues();
	
EndProcedure

&AtServer
Procedure SetAvailability(DataPathAttribute = "")
	
	If DataPathAttribute = "ConstantsSet.FilesStorageMethod" Then
		ConfigureSettingsOfStorageInVolumesAvailability();
	EndIf;
	
	If DataPathAttribute = "DenyUploadFilesByExtension"
		Or DataPathAttribute = "" Then
		
		Items.DeniedDataAreaExtensionsList.Enabled = DenyUploadFilesByExtension;
	EndIf;
	
	If DataPathAttribute = "ConstantsSet.SynchronizeFiles"
		Or DataPathAttribute = "AllowAccessToInternetServices" 
		Or DataPathAttribute = ""  Then
		
		AllowAccessToInternetServices = Common.AccessToInternetServicesAllowed();
		Items.FileSynchronizationSettings.Enabled = ConstantsSet.SynchronizeFiles
			And AllowAccessToInternetServices;
		Items.SynchronizeFiles1.Visible = Not AllowAccessToInternetServices;
		Items.SynchronizeFiles.Visible = AllowAccessToInternetServices;
		Items.GroupCommentAllowInternetDownloadsInSync.Visible = Not AllowAccessToInternetServices;
		 
	EndIf;

	If DataPathAttribute = "UseFileArchive" Then
		SetFileArchiveManagementSettingsAvailability();
	EndIf;	

EndProcedure

&AtServer
Procedure ConfigureSettingsOfStorageInVolumesAvailability()

	StorageMethodUsesVolumes = FileArchiveManagementClientServer.StorageMethodUsesVolumes(ConstantsSet.FilesStorageMethod);

	Items.FilesVolumesManagementGroup.Enabled = StorageMethodUsesVolumes;
	Items.CatalogFileStorageVolumes.Enabled = StorageMethodUsesVolumes;

	Items.CreateSubdirectoriesWithOwnersNames.Enabled = ConstantsSet.StoreFilesInVolumesOnHardDrive;
	Items.FilesSizeManagementInIBGroup.Enabled =
		ConstantsSet.FilesStorageMethod = "InInfobaseAndVolumesOnHardDrive";
	Items.IBFilesExtensionsManagementGroup.Enabled =
		ConstantsSet.FilesStorageMethod = "InInfobaseAndVolumesOnHardDrive";
	Items.GroupDeduplication.Visible = ConstantsSet.FilesStorageMethod <> "InVolumesOnHardDrive" And Not IsDeduplicationCompleted();
	
EndProcedure

&AtServer
Function SaveAttributeValue(DataPathAttribute)
	
	NameParts = StrSplit(DataPathAttribute, ".");
	If NameParts.Count() <> 2 Then
		
		If DataPathAttribute = "MaxFileSize" Then
			ConstantsSet.MaxFileSize = MaxFileSize * (1024*1024);
			ConstantName = "MaxFileSize";
		ElsIf DataPathAttribute = "MaxDataAreaFileSize" Then
			
			If Not Common.DataSeparationEnabled() Then
				ConstantsSet.MaxFileSize = MaxDataAreaFileSize * (1024*1024);
				ConstantName = "MaxFileSize";
			Else
				ConstantsSet.MaxDataAreaFileSize = MaxDataAreaFileSize * (1024*1024);
				ConstantName = "MaxDataAreaFileSize";
			EndIf;
			
		ElsIf DataPathAttribute = "DenyUploadFilesByExtension" Then
			ConstantsSet.DenyUploadFilesByExtension = DenyUploadFilesByExtension;
			ConstantName = "DenyUploadFilesByExtension";
		ElsIf DataPathAttribute = "UseFileArchive" Then
			ConstantsSet.UseFileArchive = UseFileArchive;
			ConstantName = "UseFileArchive";

			OnChangeFileArchiveUse(UseFileArchive);
		EndIf;
		
	Else
		ConstantName = NameParts[1];
	EndIf;
	
	If IsBlankString(ConstantName) Then
		Return "";
	EndIf;
	
	ConstantManager = Constants[ConstantName];
	ConstantValue = ConstantsSet[ConstantName];
	
	If ConstantManager.Get() <> ConstantValue Then
		ConstantManager.Set(ConstantValue);
	EndIf;
	
	Return ConstantName;
	
EndFunction

&AtServerNoContext
Procedure SetParametersOfFilesStorageInIB(StorageParameters)
	
	FilesOperationsInVolumesInternal.SetFilesStorageParametersInInfobase(StorageParameters);
	
EndProcedure

&AtServerNoContext
Function PermissionRequestsToUseExternalResourcesOfFilesStorageVolumes(Include)
	
	PermissionRequestsToUse = New Array;
	CatalogName = "FileStorageVolumes";
	
	If Include Then
		Catalogs[CatalogName].AddRequestsToUseExternalResourcesForAllVolumes(PermissionRequestsToUse);
	Else
		Catalogs[CatalogName].AddRequestsToStopUsingExternalResourcesForAllVolumes(PermissionRequestsToUse);
	EndIf;
	
	Return PermissionRequestsToUse;
	
EndFunction

&AtServerNoContext
Function HasFileStorageVolumes(Val FilesStorageProcessedMethod = Undefined)

	If FilesStorageProcessedMethod = Undefined Then
		
		StorageVolumeType = Undefined;
		FilesStorageMethod = Undefined;
	Else

		StorageVolumeType = Enums.StorageKinds.OperationalStorage;

		FilesStorageMethod = FileArchiveManagementServer.StorageMethodToSelectStorageVolumes(FilesStorageProcessedMethod);

	EndIf;

	Return FilesOperationsInVolumesInternal.HasFileStorageVolumes(StorageVolumeType, FilesStorageMethod);

EndFunction

&AtServer
Function StartDeduplicationAtServer()
	
	DeduplicationResultAddress = PutToTempStorage(Undefined, UUID);
	Return TimeConsumingOperations.ExecuteProcedure(, "InformationRegisters.FileRepository.TransferData_", True, DeduplicationResultAddress);
	
EndFunction

// Parameters:
//  Result - See TimeConsumingOperationsClient.NewResultLongOperation
//  AdditionalParameters - Undefined
//
&AtClient
Procedure FinishDeduplication(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		ShowMessageBox(, NStr("vi = 'Đã ngắt loại bỏ trùng lặp, nếu cần có thể khởi động sau';
								|ru = 'Дедупликация прервана, при необходимости, можно запустить позднее';
								|en = 'Deduplication has been paused and can be resumed later.'; fa = 'Deduplication has been paused and can be resumed later.';
								|it = 'Дедупликация прервана, при необходимости, можно запустить позднее';
								|pl = 'Deduplication has been paused and can be resumed later.';
								|tr = 'Tekilleştirme durduruldu, gerekirse daha sonra başlatılabilir'"));
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		StandardSubsystemsClient.OutputErrorInfo(
			Result.ErrorInfo);
		Return;
	EndIf;
	
	DeduplicationErrors = GetFromTempStorage(DeduplicationResultAddress);
	If IsDeduplicationCompleted() And DeduplicationErrors = Undefined Then
		Items.GroupDeduplication.Visible = False;
		ShowMessageBox(, NStr("vi = 'Đã hoàn tất loại bỏ trùng lặp tệp.';
								|ru = 'Дедупликация файлов завершена.';
								|en = 'File deduplication is completed.'; fa = 'File deduplication is completed.';
								|it = 'Дедупликация файлов завершена.';
								|pl = 'File deduplication is completed.';
								|tr = 'Dosya tekilleştirmesi bitti.'"));
	ElsIf DeduplicationErrors = Undefined Then
		ShowMessageBox(, NStr("vi = 'Đã xử lý không phải tất cả các tệp, cần khởi động lại.';
								|ru = 'Не все файлы были обработаны, требуется повторный запуск.';
								|en = 'Some files have not been processed. Start again.'; fa = 'Some files have not been processed. Start again.';
								|it = 'Не все файлы были обработаны, требуется повторный запуск.';
								|pl = 'Some files have not been processed. Start again.';
								|tr = 'Tüm dosyalar işlenmedi; yeniden başlatma gerekiyor.'"));
	Else
		FormParameters = New Structure;
		FormParameters.Insert("Deduplication", True);
		FormParameters.Insert("Explanation", NStr("vi = 'Không phải tất cả các tệp đã được xử lý, để tiếp tục cần loại bỏ các vấn đề được xác định:';
													|ru = 'Не все файлы были обработаны, для продолжения требуется устранить выявленные проблемы:';
													|en = 'Some of the files failed to be processed. To resume, fix the following issues:'; fa = 'Some of the files failed to be processed. To resume, fix the following issues:';
													|it = 'Не все файлы были обработаны, для продолжения требуется устранить выявленные проблемы:';
													|pl = 'Some of the files failed to be processed. To resume, fix the following issues:';
													|tr = 'Tüm dosyalar işlenmedi,  devam etmek için tespit edilen hataları gidermek gerekiyor.'"));
		FormParameters.Insert("FilesWithErrors", DeduplicationErrors);
		OpenForm("DataProcessor.FileTransfer.Form.ReportForm", FormParameters);
	EndIf;
EndProcedure 

&AtServerNoContext
Function IsDeduplicationCompleted()
	
	Query = New Query;
	Query.Text = 
	"SELECT TOP 1
	|	TRUE AS Validation
	|FROM
	|	InformationRegister.DeleteFilesBinaryData AS DeleteFilesBinaryData";
	
	Return Query.Execute().IsEmpty();
	
EndFunction

&AtServerNoContext
Function FilesSizeInInfobase()
	
	IncludeObjects = New Array();
	IncludeObjects.Add(Metadata.InformationRegisters.DeleteFilesBinaryData);
	FilesSizeMB = GetDatabaseDataSize(, IncludeObjects) / 1024 / 1024;
	If FilesSizeMB > 100 Then
		FilesSizeMB = Round(FilesSizeMB, 0);
	Else
		FilesSizeMB = Round(FilesSizeMB, 2);
	EndIf;
	
	Return FilesSizeMB;
	
EndFunction

&AtClient
Procedure OpenFilesStorageVolumeCatalogListFormWithFilterByFilesStorageVolumeType(OwnerForm, ValueForFilter)

	FormParameters = New Structure("Filter, FilterValueByFilesStorageVolumeKind", New Structure("StorageVolumeType", ValueForFilter), ValueForFilter);
	OpenForm("Catalog.FileStorageVolumes.ListForm", FormParameters, OwnerForm, True);

EndProcedure

&AtServer
Procedure FilesStorageMethodConfigureChoiceList()

	If Not FileArchiveManagementServer.AreChangesInFilesStorageMethodsAvailable() Then
		Return;
	EndIf;
	
	If Items.Find("FilesStorageMethod") = Undefined Then
		Return;
	EndIf;

	ChangeableStorageMethods = New Structure;
	ChangeableStorageMethods.Insert("InVolumesOnHardDrive"						, NStr("ru = 'в томах (в сетевых каталогах)';
																						|vi = 'Volumes (network directories)';
																						|en = 'Volumes (network directories)'; fa = 'Volumes (network directories)';
																						|it = 'Volumes (network directories)';
																						|pl = 'Volumes (network directories)';
																						|tr = 'birimlerde (ağ dizinlerinde)'"));
	ChangeableStorageMethods.Insert("InInfobase"				, NStr("ru = 'в базе данных';
																		|vi = 'Database';
																		|en = 'Database'; fa = 'Database';
																		|it = 'Database';
																		|pl = 'Database';
																		|tr = 'veri tabanında'"));
	ChangeableStorageMethods.Insert("InInfobaseAndVolumesOnHardDrive"	, NStr("ru = 'в базе данных или в томах';
																				|vi = 'Volumes or database';
																				|en = 'Volumes or database'; fa = 'Volumes or database';
																				|it = 'Volumes or database';
																				|pl = 'Volumes or database';
																				|tr = 'veri tabanında veya birimlerde'"));
	
	ChoiceListFilesStorageMethod = Items.FilesStorageMethod.ChoiceList;
	
	For Each ChangeableStorageMethod In ChangeableStorageMethods Do
		SearchResult = ChoiceListFilesStorageMethod.FindByValue(ChangeableStorageMethod.Key);
		If SearchResult <> Undefined Then
			SearchResult.Presentation = ChangeableStorageMethod.Value;
		EndIf;		
	EndDo;
	
	If Not AreBinaryDataStoragesAvailable Then
		Return;
	EndIf;

	ChoiceListFilesStorageMethod.Add("InternalBinaryDataStorage"	, NStr("ru = 'во встроенном хранилище двоичных данных (КОРП)';
																			|vi = 'Internal binary data storage (CORP)';
																			|en = 'Internal binary data storage (CORP)'; fa = 'Internal binary data storage (CORP)';
																			|it = 'Internal binary data storage (CORP)';
																			|pl = 'Internal binary data storage (CORP)';
																			|tr = 'dahili ikili veri deposunda (CORP)'"));
	ChoiceListFilesStorageMethod.Add("ExternalBinaryDataStorage"	, NStr("ru = 'во внешнем хранилище двоичных данных (КОРП)';
																			|vi = 'External binary data storage (CORP)';
																			|en = 'External binary data storage (CORP)'; fa = 'External binary data storage (CORP)';
																			|it = 'External binary data storage (CORP)';
																			|pl = 'External binary data storage (CORP)';
																			|tr = 'harici ikili veri deposunda (CORP)'"));

EndProcedure

&AtClient
Function IsFilesStorageMethodOnDisk(FilesStorageMethodBeingChecked)

	Return FilesOperationsClientServer.ShouldStoreFilesInVolumes(FilesStorageMethodBeingChecked);

EndFunction

&AtClient
Function GetWarningTextByFilesStorageMethod(FilesStorageProcessedMethod)

	Result = "";

	If FilesStorageProcessedMethod = "InVolumesOnHardDrive" Then

		Result = NStr("ru = 'Включено хранение файлов в томах на файловом сервере, но тома еще не настроены.';
						|vi = 'File storage on the file server is enabled, but archive volumes are not configured yet.';
						|en = 'File storage on the file server is enabled, but archive volumes are not configured yet.'; fa = 'File storage on the file server is enabled, but archive volumes are not configured yet.';
						|it = 'File storage on the file server is enabled, but archive volumes are not configured yet.';
						|pl = 'File storage on the file server is enabled, but archive volumes are not configured yet.';
						|tr = 'Dosyaların dosya sunucusundaki birimlerde saklanması etkinleştirildi ancak birimler henüz yapılandırılmadı.'");

	ElsIf FilesStorageProcessedMethod = "InInfobaseAndVolumesOnHardDrive" Then

		Result = NStr("ru = 'Включено хранение файлов в базе данных и внешних местах хранения, но тома хранения файлов еще не настроены.';
						|vi = 'File storage in the database and external storage is enabled, but storage volumes are not configured yet.';
						|en = 'File storage in the database and external storage is enabled, but storage volumes are not configured yet.'; fa = 'File storage in the database and external storage is enabled, but storage volumes are not configured yet.';
						|it = 'File storage in the database and external storage is enabled, but storage volumes are not configured yet.';
						|pl = 'File storage in the database and external storage is enabled, but storage volumes are not configured yet.';
						|tr = 'Dosyaların veri tabanında ve harici saklama yerlerinde saklanması etkinleştirildi ancak dosya saklama birimleri henüz yapılandırılmadı.'");

	ElsIf FilesStorageProcessedMethod = "InternalBinaryDataStorage" Then

		Result = NStr("ru = 'Включено хранение файлов во встроенном хранилище двоичных данных, но том хранения файлов еще не настроен.';
						|vi = 'File storage in the internal binary data repository is enabled, but storage volumes are not configured yet.';
						|en = 'File storage in the internal binary data repository is enabled, but storage volumes are not configured yet.'; fa = 'File storage in the internal binary data repository is enabled, but storage volumes are not configured yet.';
						|it = 'File storage in the internal binary data repository is enabled, but storage volumes are not configured yet.';
						|pl = 'File storage in the internal binary data repository is enabled, but storage volumes are not configured yet.';
						|tr = 'Dosyaların dahili ikili veri deposunda saklanması etkinleştirildi ancak dosya saklama birimi henüz yapılandırılmadı.'");

	ElsIf FilesStorageProcessedMethod = "ExternalBinaryDataStorage" Then
		
		Result = NStr("ru = 'Включено хранение файлов во внешнем хранилище двоичных данных, но том хранения файлов еще не настроен.';
						|vi = 'File storage in the external binary data repository is enabled, but storage volumes are not configured yet.';
						|en = 'File storage in the external binary data repository is enabled, but storage volumes are not configured yet.'; fa = 'File storage in the external binary data repository is enabled, but storage volumes are not configured yet.';
						|it = 'File storage in the external binary data repository is enabled, but storage volumes are not configured yet.';
						|pl = 'File storage in the external binary data repository is enabled, but storage volumes are not configured yet.';
						|tr = 'Dosyaların harici ikili veri deposunda saklanması etkinleştirildi ancak dosya saklama birimi henüz yapılandırılmadı.'");

	EndIf;

	If Not IsBlankString(Result) Then

		MessageTemplate = NStr("ru = '%1
		|Добавляемые файлы будут сохраняться в информационной базе до тех пор, пока не будет настроен хотя бы один том хранения файлов.';
		|vi = '%1
		|Files will be stored in the infobase until a file storage volume is configured.';
		|en = '%1
		|Files will be stored in the infobase until a file storage volume is configured.'; fa = '%1
		|Files will be stored in the infobase until a file storage volume is configured.';
		|it = '%1
		|Files will be stored in the infobase until a file storage volume is configured.';
		|pl = '%1
		|Files will be stored in the infobase until a file storage volume is configured.';
		|tr = '%1
		|En az bir dosya saklama birimi yapılandırılana kadar eklenen dosyalar bilgi tabanında saklanacaktır.'");

		Result = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, Result);

	EndIf;

	Return Result;

EndFunction

&AtServerNoContext
Procedure ChangeStoredDataComposition(FilesStorageMethod)

	AttributesForStoredDataCompositionSetting = FileArchiveManagementServer.FilesStorageAttributesNamesByStorageMethod(FilesStorageMethod);

	If IsChangeStoredDataCompositionRequired(FilesStorageMethod, AttributesForStoredDataCompositionSetting) Then
		BinaryDataStorageManagementServer.ConfigureCompositionOfStoredDataFiles(AttributesForStoredDataCompositionSetting);
	EndIf;

EndProcedure

&AtServerNoContext
Function IsChangeStoredDataCompositionRequired(FilesStorageMethod, AttributesForDataStorage)

	If BinaryDataStorageManagementServer.AreBinaryDataStoragesMissing() Then
		Return False;
	EndIf;

	For Each FilesStorageAttributeName In AttributesForDataStorage Do

		If BinaryDataStorageManagementServer.IsSettingForStorageDataCompositionForAttributeRequired(FilesStorageAttributeName, FilesStorageMethod) Then
			Return True;
		EndIf;

	EndDo;

	Return False;

EndFunction

&AtServer
Procedure SetFileArchiveManagementSettingsAvailability()

	Items.FileArchiveOperationsSetting							.Enabled = UseFileArchive;
	Items.FilesStorageVolumesCatalogArchiveItems						.Enabled = UseFileArchive;
	Items.NotificationAboutFileUnavailabilityInTheArchive	.Enabled = UseFileArchive;

EndProcedure

&AtServerNoContext
Procedure OnChangeFileArchiveUse(UseFileArchive)

	JobParameters = New Structure;
	JobParameters.Insert("Metadata", Metadata.ScheduledJobs.TransferFilesBetweenOperationalStorageAndArchive);
	If Not Common.DataSeparationEnabled() Then
		JobParameters.Insert("MethodName", Metadata.ScheduledJobs.TransferFilesBetweenOperationalStorageAndArchive.MethodName);
	EndIf;
	
	SetPrivilegedMode(True);
	
	JobsList = ScheduledJobsServer.FindJobs(JobParameters);
	ParameterName = "Use";
	If JobsList.Count() = 0 Then
		JobParameters.Insert(ParameterName, UseFileArchive);
		ScheduledJobsServer.AddJob(JobParameters);
	Else
		JobParameters = New Structure(ParameterName, UseFileArchive);
		For Each Job In JobsList Do
			ScheduledJobsServer.ChangeJob(Job, JobParameters);
		EndDo;
	EndIf;
EndProcedure

#EndRegion