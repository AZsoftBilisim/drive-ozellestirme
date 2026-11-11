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
	
	MaxFileSize = FilesOperations.MaxFileSizeCommon() / (1024*1024);

	MetadataNamesArray = New Array();
	MetadataNamesArray.Add("InformationRegister.DeleteFilesBinaryData");
	DeleteFilesBinaryDataTableSize = 
		GetDatabaseDataSize(Undefined, MetadataNamesArray) / (1024*1024);
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Not Exit Then
		RefreshApplicationInterface();
	EndIf;
	
EndProcedure

#EndRegion 

#Region FormHeaderItemsEventHandlers

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

#Region FormCommandsEventHandlers

&AtClient
Async Procedure StartDeduplication(Command)
	
	QuestionTitle = NStr("vi = 'Loại bỏ trùng lặp tệp';
						|ru = 'Дедупликация файлов';
						|en = 'File deduplication'; fa = 'حذف تکرار فایل';
						|it = 'Дедупликация файлов';
						|pl = 'File deduplication';
						|tr = 'Dosya tekilleştirme'");
	QueryText = NStr("vi = 'Việc loại bỏ trùng lặp tệp cho phép tiết kiệm tới 30% dung lượng trong cơ sở thông tin bằng cách loại bỏ các tệp trùng lặp mà được lưu trữ trong ứng dụng (tùy chọn lưu trữ ""Trong cơ sở thông tin""). Việc loại bỏ trùng lặp các tệp hiện có mất từ ​​​​vài phút đến vài giờ, tùy thuộc vào dung lượng tệp trong ứng dụng. Nó có thể bị gián đoạn bất cứ lúc nào và được tiếp tục lại sau đó vào thời điểm thích hợp hơn. Trong trường hợp này, sẽ tự động lưu lại tất cả các tệp mới được thêm trong ứng dụng chỉ trong một bản sao.
						|
						|Trong quá trình loại bỏ trùng lặp các tệp, dung lượng cơ sở thông tin có thể tăng lên đáng kể. Do đó, trước khi bắt đầu, bạn nên:
						|• đảm bảo có đủ dung lượng trống trên thiết bị chứa cơ sở thông tin (cần ít nhất %1 Mb);
						|• tạo một bản sao lưu của cơ sở thông tin. 
						|
						|Sau khi hoàn tất, hãy nén cơ sở thông tin để quá trình loại bỏ trùng lặp tệp có hiệu lực.
						|
						|Tạo nhiệm vụ để loại bỏ trùng lặp tệp trong mỗi vùng?';
						|ru = 'Дедупликация файлов позволяет экономить до 30% места в информационной базе за счет устранения дублей файлов, хранящихся в приложении (вариант хранения ""В информационной базе""). Дедупликация имеющихся файлов занимает от нескольких минут до нескольких часов в зависимости от объема файлов в приложении. В любой момент ее можно будет прервать и возобновить позднее в более подходящий момент времени. При этом все вновь добавляемые файлы уже автоматически сохраняются в приложении только в одном экземпляре.
						|
						|Во время дедупликации файлов размер информационной базы может существенно вырасти. Поэтому перед запуском рекомендуется:
						|• убедиться, что имеется достаточно свободного места на устройстве, где размещается информационная база (требуется не менее %1 Мб);
						|• сделать резервную копию информационной базы.
						|
						|После завершения выполнить сжатие информационной базы, чтобы дедупликация файлов вступила в силу.
						|
						|Создать задания для дедупликации файлов в каждой области ?';
						|en = 'With file deduplication, you can save up to 30% of infobase space by removing duplicate files stored in the application (the ""Infobase"" storage option). The process takes minutes to hours, depending on the number of files, and can be paused and resumed at any time. All newly added files are automatically stored as a single instance.
						|
						|During deduplication, the infobase size may increase significantly. Therefore, before initiating the process, ensure that the device hosting the infobase has at least %1 MB of free space and back up the infobase. After completion, compress the infobase for the deduplication to take effect.
						|
						|Do you want to create deduplication jobs for each data area?'; fa = 'With file deduplication, you can save up to 30% of infobase space by removing duplicate files stored in the application (the ""Infobase"" storage option). The process takes minutes to hours, depending on the number of files, and can be paused and resumed at any time. All newly added files are automatically stored as a single instance.
						|
						|During deduplication, the infobase size may increase significantly. Therefore, before initiating the process, ensure that the device hosting the infobase has at least %1 MB of free space and back up the infobase. After completion, compress the infobase for the deduplication to take effect.
						|
						|Do you want to create deduplication jobs for each data area?';
						|it = 'Дедупликация файлов позволяет экономить до 30% места в информационной базе за счет устранения дублей файлов, хранящихся в приложении (вариант хранения ""В информационной базе""). Дедупликация имеющихся файлов занимает от нескольких минут до нескольких часов в зависимости от объема файлов в приложении. В любой момент ее можно будет прервать и возобновить позднее в более подходящий момент времени. При этом все вновь добавляемые файлы уже автоматически сохраняются в приложении только в одном экземпляре.
						|
						|Во время дедупликации файлов размер информационной базы может существенно вырасти. Поэтому перед запуском рекомендуется:
						|• убедиться, что имеется достаточно свободного места на устройстве, где размещается информационная база (требуется не менее %1 Мб);
						|• сделать резервную копию информационной базы.
						|
						|После завершения выполнить сжатие информационной базы, чтобы дедупликация файлов вступила в силу.
						|
						|Создать задания для дедупликации файлов в каждой области ?';
						|pl = 'With file deduplication, you can save up to 30% of infobase space by removing duplicate files stored in the application (the ""Infobase"" storage option). The process takes minutes to hours, depending on the number of files, and can be paused and resumed at any time. All newly added files are automatically stored as a single instance.
						|
						|During deduplication, the infobase size may increase significantly. Therefore, before initiating the process, ensure that the device hosting the infobase has at least %1 MB of free space and back up the infobase. After completion, compress the infobase for the deduplication to take effect.
						|
						|Do you want to create deduplication jobs for each data area?';
						|tr = 'Dosya tekilleştirme, uygulamada depolanan yinelenen dosyaları ortadan kaldırarak bilgi tabanında %30''a kadar alan tasarrufu sağlar (""Bilgi tabanında"" depolama seçeneği). Mevcut dosyaların tekilleştirilmesi, uygulamadaki dosyaların boyutuna bağlı olarak birkaç dakikadan birkaç saate kadar sürebilir. Herhangi bir zamanda kesintiye uğratılabilir ve daha sonra daha uygun bir zamanda yeniden başlatılabilir. Bu durumda, yeni eklenen tüm dosyalar uygulamaya otomatik olarak tek bir kopya halinde kaydedilir.
						|
						|Dosya tekilleştirme sırasında bilgi tabanının boyutu önemli ölçüde büyüyebilir. Bu nedenle, başlamadan önce şunları yapmanız önerilir:
						|• bilgi tabanının bulunduğu cihazda yeterli boş alan olduğundan emin olun (en az %1 MB gereklidir);
						|• bilgi tabanının yedek bir kopyasını oluşturun. 
						|
						|Tamamlandıktan sonra, dosya tekilleştirme işleminin etkili olması için bilgi tabanını sıkıştırın.
						|
						|Her alanda dosya tekilleştirme işleri oluşturulsun mu?'");
	QueryText = StringFunctionsClientServer.SubstituteParametersToString(QueryText, Format(DeleteFilesBinaryDataTableSize, "NFD=2;"));
	
	Response = Await DoQueryBoxAsync(QueryText, QuestionDialogMode.YesNo, , DialogReturnCode.No, QuestionTitle);
	If Response = DialogReturnCode.Yes Then
		RunDeduplicationAtServer();
	EndIf;

EndProcedure

#EndRegion

#Region Private 

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
	
	RefreshReusableValues();
	
	Return ConstantName;
	
EndFunction

&AtServer
Function SaveAttributeValue(DataPathAttribute)
	
	NameParts = StrSplit(DataPathAttribute, ".");
	If NameParts.Count() <> 2 Then
		
		If DataPathAttribute = "MaxFileSize" Then
			ConstantsSet.MaxFileSize = MaxFileSize * (1024*1024);
			ConstantName = "MaxFileSize";
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
Procedure RunDeduplicationAtServer()
	
	If Common.SubsystemExists("StandardSubsystems.SaaSOperations.FilesOperationsSaaS") Then
		
		ModuleFilesOperationsInternalSaaS = Common.CommonModule("FilesOperationsInternalSaaS");
		ModuleFilesOperationsInternalSaaS.StartDeduplication();
		
	EndIf;
	
EndProcedure

#EndRegion
