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
Var ClientParameters Export;

&AtClient
Var DataDetails, ObjectForm, CurrentPresentationsList;

&AtClient
Var DataRepresentationRefreshed;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	AutoTitle = False;
	If Common.IsMobileClient() Then
		Title = NStr("vi = 'Thêm chữ ký điện tử từ tệp trên thiết bị';
					|ru = 'Добавление электронных подписей из файлов на устройстве';
					|en = 'Add digital signature from device''s files'; fa = 'Add digital signature from device''s files';
					|it = 'Добавление электронных подписей из файлов на устройстве';
					|pl = 'Add digital signature from device''s files';
					|tr = 'Cihazdaki dosyalardan elektronik imzaların eklenmesi'");
		Items.SignaturesAdd.Title = NStr("vi = 'Chọn tệp từ thiết bị...';
										|ru = 'Выбрать файлы с устройства...';
										|en = 'Select files on disk…'; fa = 'انتخاب فایل‌ها روی دیسک…';
										|it = 'Выбрать файлы с устройства...';
										|pl = 'Select files on disk…';
										|tr = '...cihazından dosya seçmek'");
	Else
		Title = NStr("vi = 'Thêm chữ ký điện tử từ tệp trên máy tính thiết bị';
					|ru = 'Добавление электронных подписей из файлов на компьютере';
					|en = 'Add digital signatures from device''s files'; fa = 'Add digital signatures from device''s files';
					|it = 'Добавление электронных подписей из файлов на компьютере';
					|pl = 'Add digital signatures from device''s files';
					|tr = 'Bilgisayardaki dosyalardan elektronik imzaların eklenmesi'");
	EndIf;
	
	If ValueIsFilled(Parameters.DataTitle) Then
		Items.DataPresentation.Title = Parameters.DataTitle;
	Else
		Items.DataPresentation.TitleLocation = FormItemTitleLocation.None;
	EndIf;
	
	DataPresentation = Parameters.DataPresentation;
	Items.DataPresentation.Hyperlink = Parameters.DataPresentationCanOpen;
	
	If Not ValueIsFilled(DataPresentation) Then
		Items.DataPresentation.Visible = False;
	EndIf;
	
	If Not Parameters.ShowComment Then
		Items.Signatures.Header = False;
		Items.SignaturesComment.Visible = False;
	EndIf;
	
	CryptographyManagerOnServerErrorDescription = New Structure;
	
	If DigitalSignature.VerifyDigitalSignaturesOnTheServer()
	 Or DigitalSignature.GenerateDigitalSignaturesAtServer() Then
		
		CreationParameters = DigitalSignatureInternal.CryptoManagerCreationParameters();
		CreationParameters.ErrorDescription = New Structure;
		
		DigitalSignatureInternal.CryptoManager("", CreationParameters);
		CryptographyManagerOnServerErrorDescription = CreationParameters.ErrorDescription;
		
	EndIf;
	
	DigitalSignatureLocalization.OnCreateAtServer(ThisObject);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If ClientParameters = Undefined Then
		Cancel = True;
	Else
		DataDetails             = ClientParameters.DataDetails;
		ObjectForm               = ClientParameters.Form;
		CurrentPresentationsList = ClientParameters.CurrentPresentationsList;
		AttachIdleHandler("AfterOpen", 0.1, True);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DataPresentationClick(Item, StandardProcessing)
	
	DigitalSignatureInternalClient.DataPresentationClick(ThisObject,
		Item, StandardProcessing, CurrentPresentationsList);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersSignatures

&AtClient
Procedure SignaturesBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	
	If DataRepresentationRefreshed = True Then
		SelectFiles(True);
	EndIf;
	
EndProcedure

&AtClient
Procedure SignaturesPathToFileStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	SelectFiles();
	
EndProcedure

&AtClient
Procedure SignaturesMachineReadableLetterOfAuthorityStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	SignaturesMachineReadableLetterOfAuthorityStartChoiceContinued(Item, ChoiceData);
	
EndProcedure

&AtClient
Async Procedure SignaturesMachineReadableLetterOfAuthorityStartChoiceContinued(Item, ChoiceData)
	
	CurrentData = Items.Signatures.CurrentData;
	
	ChoiceList = New ValueList;
	DigitalSignatureClientLocalization.OnGetChoiceListWithMRLOAs(
		ThisObject, CurrentData, ChoiceList);
	
	If ChoiceList.Count() > 0 Then
		ChoiceList.Add("ChooseFromCatalog", NStr("vi = 'Chọn từ danh mục...';
												|ru = 'Выбрать из справочника...';
												|en = 'Select from catalog…'; fa = 'Select from catalog…';
												|it = 'Выбрать из справочника...';
												|pl = 'Select from catalog…';
												|tr = 'Dizinden seçin..'"));
		Result = Await ChooseFromListAsync(ChoiceList, Items.SignaturesMachineReadableLetterOfAuthority);
		If Result <> Undefined Then
			If Result.Value = "ChooseFromCatalog" Then
				MRLOASelectFromCatalog();
				Return;
			EndIf;
			
			CurrentData.MachineReadableLetterOfAuthority = Result.Presentation;
			CurrentData.PowerOfAttorneyNumber_ = Result.Value;
			AttachIdleHandler("SignaturesMRLOAOnChange", 0.1, True);
		EndIf;
	Else
		MRLOASelectFromCatalog();
	EndIf;

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure PickLOAs(Command)
	
	If DataDetails.Property("Object") And TypeOf(DataDetails.Object) <> Type("CallbackDescription") Then
		FillMRLOAs(DataDetails.Object);
	Else
		FillMRLOAs();
	EndIf;
	
EndProcedure

&AtClient
Procedure OK(Command)
	
	If Signatures.Count() = 0 Then
		ShowMessageBox(, NStr("vi = 'Chưa chọn tệp chữ ký nào';
								|ru = 'Не выбрано ни одного файла подписи';
								|en = 'No signature file is selected'; fa = 'No signature file is selected';
								|it = 'Nessun file di firma selezionato';
								|pl = 'Nie wybrano żadnego pliku podpisu';
								|tr = 'Hiçbir imza dosyası seçilmedi'"));
		Return;
	EndIf;
	
	ImportMRLOAs();
		
	If Not DataDetails.Property("Object") Then
		DataDetails.Insert("Signatures", SignaturesToBeAdded());
		Close(True);
		Return;
	EndIf;
	
	If TypeOf(DataDetails.Object) <> Type("CallbackDescription") Then
		ObjectVersion = Undefined;
		DataDetails.Property("ObjectVersion", ObjectVersion);
		Try
			SignaturesArray = AddSignature(DataDetails.Object, ObjectVersion);
		Except
			ErrorInfo = ErrorInfo();
			OKCompletion(New Structure("ErrorDescription", ErrorProcessing.BriefErrorDescription(ErrorInfo)));
			Return;
		EndTry;
		DataDetails.Insert("Signatures", SignaturesArray);
		NotifyChanged(DataDetails.Object);
	Else
		DataDetails.Insert("Signatures", SignaturesToBeAdded());
		
		ExecutionParameters = New Structure;
		ExecutionParameters.Insert("DataDetails", DataDetails);
		ExecutionParameters.Insert("Notification", New CallbackDescription("OKCompletion", ThisObject));
		
		Try
			RunCallback(DataDetails.Object, ExecutionParameters);
			Return;
		Except
			ErrorInfo = ErrorInfo();
			OKCompletion(New Structure("ErrorDescription", ErrorProcessing.BriefErrorDescription(ErrorInfo)));
			Return;
		EndTry;
	EndIf;
	
	OKCompletion(New Structure);
	
EndProcedure

// Continues the OK procedure.
&AtClient
Procedure OKCompletion(Result, Context = Undefined) Export
	
	If Result.Property("ErrorDescription") Then
		DataDetails.Delete("Signatures");
		
		Error = New Structure("ErrorDescription",
			NStr("vi = 'Không thể ghi lại chữ ký do nguyên nhân:';
				|ru = 'Не удалось записать подпись по причине:';
				|en = 'Cannot save the signature due to:'; fa = 'Cannot save the signature due to:';
				|it = 'Не удалось записать подпись по причине:';
				|pl = 'Cannot save the signature due to:';
				|tr = 'İmza şu sebeple kaydedilemedi:'") + Chars.LF + Result.ErrorDescription);
			
		DigitalSignatureInternalClient.ShowApplicationCallError(
			NStr("vi = 'Không thể thêm chữ ký điện tử từ tệp';
				|ru = 'Не удалось добавить электронную подпись из файла';
				|en = 'Cannot add a digital signature from the file'; fa = 'Cannot add a digital signature from the file';
				|it = 'Non è stato possibile aggiugnere la firma elettronica dal file';
				|pl = 'Dodawanie podpisu elektronicznego z pliku nie powiodło się';
				|tr = 'Dosyadan dijital imza eklenemedi'"), "", Error, New Structure);
		Return;
	EndIf;
	
	If ValueIsFilled(DataPresentation) Then
		DigitalSignatureClient.ObjectSigningInfo(
			DigitalSignatureInternalClient.FullDataPresentation(ThisObject),, True);
	EndIf;
	
	Close(True);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure AfterOpen()
	
	DataRepresentationRefreshed = True;
	SelectFiles(True);
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SignaturesPathToFile.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Signatures.PathToFile");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
EndProcedure

&AtClient
Async Procedure SelectFiles(MultipleChoice = False, RepeatedCall = False)
	
	If Not RepeatedCall Then
		NotificationWhenDigitalSignatureAddInsMissing = New CallbackDescription("ReSelectFilesAfterAddInInstalled", ThisObject, MultipleChoice);
		IsInstallingAddIns = Await DigitalSignatureInternalClient.InstallAddInsAfter1CEnterpriseExtensionChecked(
			NotificationWhenDigitalSignatureAddInsMissing);
		If IsInstallingAddIns Then
			Return;
		EndIf;
	EndIf;
	
	ErrorOnLOAsImport = "";
	LettersOfAuthority.Clear();
	
	Context = New Structure;
	Context.Insert("AddNewRows", MultipleChoice);
	
	Notification = New CallbackDescription("SelectFilesAfterPutFiles", ThisObject, Context);
	
	ImportParameters = FileSystemClient.FileImportParameters();
	ImportParameters.FormIdentifier = UUID;
	
	If MultipleChoice Then
		ImportParameters.Dialog.Title = NStr("vi = 'Chọn tệp chữ ký điện tử';
											|ru = 'Выберите файлы электронной подписи';
											|en = 'Select digital signature files'; fa = 'Select digital signature files';
											|it = 'Выберите файлы электронной подписи';
											|pl = 'Select digital signature files';
											|tr = 'Dijital imza dosyalarını seçiniz'");
	Else
		ImportParameters.Dialog.Title = NStr("vi = 'Hãy chọn tệp chữ ký điện tử';
											|ru = 'Выберите файл электронной подписи';
											|en = 'Select a digital signature file'; fa = 'Select a digital signature file';
											|it = 'Выберите файл электронной подписи';
											|pl = 'Wybierz plik podpisu elektronicznego';
											|tr = 'Dijital imza dosyasını seçiniz'");
	EndIf;
	ImportParameters.Dialog.Multiselect = MultipleChoice;
	
	FilterForSelectingSignatures = NStr("vi = 'Tệp chữ ký (*.p7s, *.sig%1)|*.p7s;*.sig%2';
										|ru = 'Файлы подписи (*.p7s, *.sig%1)|*.p7s;*.sig%2';
										|en = 'SIgnature files (*.p7s, *.sig%1)|*.p7s;*.sig%2'; fa = 'SIgnature files (*.p7s, *.sig%1)|*.p7s;*.sig%2';
										|it = 'Файлы подписи (*.p7s, *.sig%1)|*.p7s;*.sig%2';
										|pl = 'SIgnature files (*.p7s, *.sig%1)|*.p7s;*.sig%2';
										|tr = 'İmza dosyaları (*.p7s, *.sig%1)|*.p7s;*.sig%2'");
	DigitalSignatureClientLocalization.OnGetFilterForSelectingSignatures(FilterForSelectingSignatures);
		
	SignatureFilesExtension = DigitalSignatureClient.PersonalSettings().SignatureFilesExtension;
	If StrFind(FilterForSelectingSignatures, SignatureFilesExtension) = 0 Then
		FilterForSelectingSignatures= StringFunctionsClientServer.SubstituteParametersToString(FilterForSelectingSignatures,
			", *." + SignatureFilesExtension, ";*." + SignatureFilesExtension);
	Else		
		FilterForSelectingSignatures= StringFunctionsClientServer.SubstituteParametersToString(FilterForSelectingSignatures, "", "");
	EndIf;
	
	ImportParameters.Dialog.Filter = FilterForSelectingSignatures;
	ImportParameters.Dialog.Filter = ImportParameters.Dialog.Filter + "|" + StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Tất cả tệp (%1)|%1';
																																			|ru = 'Все файлы (%1)|%1';
																																			|en = 'All files (%1)|%1'; fa = 'All files (%1)|%1';
																																			|it = 'Все файлы (%1)|%1';
																																			|pl = 'All files (%1)|%1';
																																			|tr = 'Tüm dosyalar ( 1 )| 1'"), GetAllFilesMask());
	
	If Not MultipleChoice Then
		ImportParameters.Dialog.FullFileName = Items.Signatures.CurrentData.PathToFile;
	EndIf;
	
	FileSystemClient.ImportFiles(Notification, ImportParameters);
	
EndProcedure

// Follow-up call to "SelectFile" after the add-ins have been installed.
&AtClient
Procedure ReSelectFilesAfterAddInInstalled(Result, MultipleChoice) Export
	
	If Result = True Then
		SelectFiles(MultipleChoice, True)
	EndIf;
	
EndProcedure

// Continues the SelectFile procedure.
&AtClient
Procedure SelectFilesAfterPutFiles(PlacedFiles, Context) Export
	
	If PlacedFiles = Undefined Then
		Return;
	EndIf;
	
	If TypeOf(PlacedFiles) = Type("File") Then
		PlacedFiles = CommonClientServer.ValueInArray(PlacedFiles);
	EndIf;
		
	Result = AddRowsOnServer(PlacedFiles, Context.AddNewRows);
	
	Context.Insert("PlacedFiles", PlacedFiles);
	Context.Insert("DataToValidateSignature", Undefined);
	Context.Insert("SignaturesAdditionResult", Result);
	Context.Insert("OtherFiles", Result);
	Context.Insert("Errors", New Structure("ErrorsAtClient, ErrorsAtServer", New Map, New Map));
	Context.Insert("IndexOf", -1);
	SelectFilesLoopStart(Context);
	
EndProcedure

&AtClient
Procedure SelectFilesLoopStart(Context)
	
	If Context.PlacedFiles.Count() <= Context.IndexOf + 1 Then
		SelectFilesAfterLoop(Context);
		Return;
	EndIf;
	
	Context.IndexOf = Context.IndexOf + 1;
	
	FileThatWasPut = Context.PlacedFiles[Context.IndexOf];
	
	NameContent = CommonClientServer.ParseFullFileName(FileThatWasPut.Name);

	SignatureAdditionResult = Context.SignaturesAdditionResult.Get(FileThatWasPut.Name);
	
	If SignatureAdditionResult = Undefined Then
		SelectFilesLoopStart(Context);
		Return;
	EndIf;
	
	Context.Insert("SignatureAdditionResult", SignatureAdditionResult);
	
	If SignatureAdditionResult.Success Then
		SelectFileAfterAddRow(Context);
		Return;
	EndIf;
	
	CreationParameters = DigitalSignatureInternalClient.CryptoManagerCreationParameters();
	CreationParameters.SignAlgorithm = DigitalSignatureInternalClientServer.GeneratedSignAlgorithm(
			Context.SignatureAdditionResult.SignatureData);
	CreationParameters.ShowError = Undefined;

	DigitalSignatureInternalClient.CreateCryptoManager(
			New CallbackDescription("ChooseFileAfterCreateCryptoManager", ThisObject, Context), "",
		CreationParameters);
	
EndProcedure

&AtClient
Procedure SelectFilesAfterLoop(Context)
	
	FillMRLOAs();
	
	If Context.Errors.ErrorsAtClient.Count() = 0
		And Context.Errors.ErrorsAtServer.Count() = 0
		And ErrorOnLOAsImport = "" Then
		Return;
	EndIf;
	
	ErrorAtClient = DigitalSignatureInternalClientServer.NewErrorsDescription();
	ErrorAtClient.ErrorTitle = NStr("vi = 'Không thể thêm tệp';
									|ru = 'Не удалось добавить файлы';
									|en = 'Couldn''t add files'; fa = 'Couldn''t add files';
									|it = 'Не удалось добавить файлы';
									|pl = 'Couldn''t add files';
									|tr = 'Dosyalar eklenemedi'");
	
	For Each KeyAndValue In Context.Errors.ErrorsAtClient Do
		
		ErrorProperties = DigitalSignatureInternalClientServer.NewErrorProperties();
		If ValueIsFilled(KeyAndValue.Value.AdditionalParameters) Then
			FillPropertyValues(ErrorProperties, KeyAndValue.Value.AdditionalParameters);
		EndIf;
		
		ErrorProperties.LongDesc = StrTemplate("%1:
			|%2", KeyAndValue.Key, StrConcat(KeyAndValue.Value.Files, Chars.LF));
		ErrorAtClient.Errors.Add(ErrorProperties);
		
	EndDo;
	
	ErrorAtServer = DigitalSignatureInternalClientServer.NewErrorsDescription();
	ErrorAtServer.ErrorTitle = NStr("vi = 'Không thể thêm tệp';
									|ru = 'Не удалось добавить файлы';
									|en = 'Couldn''t add files'; fa = 'Couldn''t add files';
									|it = 'Не удалось добавить файлы';
									|pl = 'Couldn''t add files';
									|tr = 'Dosyalar eklenemedi'");
	
	If ErrorOnLOAsImport <> "" Then
		
		ErrorProperties = DigitalSignatureInternalClientServer.NewErrorProperties();
		ErrorProperties.LongDesc = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể kết nhập giấy ủy quyền:
			|%1';
			|ru = 'Не удалось загрузить доверенности:
			|%1';
			|en = 'Couldn''t import the LOAs:
			|%1'; fa = 'Couldn''t import the LOAs:
			|%1';
			|it = 'Не удалось загрузить доверенности:
			|%1';
			|pl = 'Couldn''t import the LOAs:
			|%1';
			|tr = 'Yetki belgeleri yüklenemedi:
			|%1'"), ErrorOnLOAsImport);
		ErrorAtServer.Errors.Add(ErrorProperties);
	EndIf;
	
	For Each KeyAndValue In Context.Errors.ErrorsAtServer Do
		
		ErrorProperties = DigitalSignatureInternalClientServer.NewErrorProperties();
		If ValueIsFilled(KeyAndValue.Value.AdditionalParameters) Then
			FillPropertyValues(ErrorProperties, KeyAndValue.Value.AdditionalParameters);
		EndIf;
		
		ErrorProperties.LongDesc = StrTemplate("%1:
			|%2", KeyAndValue.Key, StrConcat(KeyAndValue.Value.Files, Chars.LF));
		ErrorAtServer.Errors.Add(ErrorProperties);
		
	EndDo;
	
	ShowError(ErrorAtClient, ErrorAtServer);
	
EndProcedure

// Continues the SelectFile procedure.
&AtClient
Procedure ChooseFileAfterCreateCryptoManager(CryptoManager, Context) Export
	
	If TypeOf(CryptoManager) <> Type("CryptoManager") Then
		DigitalSignatureInternalClient.ReadSignatureProperties(New CallbackDescription(
			"SelectFileAfterSignaturePropertiesRead", ThisObject, Context),
			Context.SignatureAdditionResult.SignatureData, True, False);
		Return;
	EndIf;
	
	Context.Insert("CryptoManager", CryptoManager);
	
	CryptoManager.BeginGettingCryptoSignaturesContainer(New CallbackDescription(
		"SelectFileAfterGettingContainerSignature", ThisObject, Context,
		"SelectFileAfterReceivingSignatureContainerError", ThisObject), Context.SignatureAdditionResult.SignatureData);
	
EndProcedure

// Continues the SelectFile procedure.
&AtClient
Procedure SelectFileAfterSignaturePropertiesRead(Result, Context) Export
	
	If Result.Success = False Then
		AddError(New Structure("ErrorDescription", Result.ErrorText), Context);
		Return;
	EndIf;
	
	Context.Insert("CryptoManager", Undefined);
	Context.Insert("SignatureParameters", Result);
	
	If Result.Certificate <> Undefined Then
		
		CertificateProperties = New Structure;
		CertificateProperties.Insert("BinaryData", Result.Certificate);
		CertificateProperties.Insert("Thumbprint", Result.Thumbprint);
		CertificateProperties.Insert("IssuedTo", Result.CertificateOwner);
		
		SignatureProperties = DigitalSignatureInternalClientServer.SignatureProperties(Context.SignatureAdditionResult.SignatureData,
			CertificateProperties, "", UsersClient.AuthorizedUser(), Context.SignatureAdditionResult.FileName,
			Context.SignatureParameters, True);

		AddRow(ThisObject, Context.AddNewRows, SignatureProperties, Context.SignatureAdditionResult.FileName,
			Context.SignatureAdditionResult.SignaturePropertiesAddress);

		SelectFileAfterAddRow(Context);
	Else
		ErrorAtClient = New Structure("ErrorDescription", NStr("vi = 'Trong tệp chữ ký không có chứng thư nào.';
																|ru = 'В файле подписи нет ни одного сертификата.';
																|en = 'The signature file contains no certificates.'; fa = 'The signature file contains no certificates.';
																|it = 'Nel file di firma non vi è alcun certificato.';
																|pl = 'W pliku podpisu nie ma ani jednego certyfikatu.';
																|tr = 'İmza dosyasında hiçbir sertifika bulunmuyor.'"));

		AddError(ErrorAtClient, Context);
		
	EndIf;
	
EndProcedure

// Continues the SelectFile procedure.
&AtClient
Procedure SelectFileAfterReceivingSignatureContainerError(ErrorInfo, StandardProcessing, Context) Export
	
	StandardProcessing = False;
	
	ErrorAtClient = New Structure("ErrorDescription", StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Không thể nhận nơi chứa chữ ký từ tệp chữ ký do nguyên nhân:
		           |%1';
		           |ru = 'Не удалось получить контейнер подписи из файла подписи по причине:
		           |%1';
		           |en = 'Cannot receive the signature container from the signature file due to:
		           |%1'; fa = 'Cannot receive the signature container from the signature file due to:
		           |%1';
		           |it = 'Не удалось получить контейнер подписи из файла подписи по причине:
		           |%1';
		           |pl = 'Cannot receive the signature container from the signature file due to:
		           |%1';
		           |tr = 'İmza dosyasındaki imza konteyneri şu sebeple alınamadı:
		           |%1'"),
		ErrorProcessing.BriefErrorDescription(ErrorInfo)));
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ShowInstruction", True);
	AdditionalParameters.Insert("Signature", Context.SignatureAdditionResult.SignatureData);
	
	AddError(ErrorAtClient, Context, AdditionalParameters);
		
EndProcedure

// Continues the SelectFile procedure.
&AtClient
Async Procedure SelectFileAfterGettingContainerSignature(ContainerSignatures, Context) Export
	
	SessionDate = CommonClient.SessionDate();
	UTCOffset = SessionDate - CommonClient.UniversalDate();
	SignatureParameters = Await DigitalSignatureInternalClient.ParametersCryptoSignatures(
		ContainerSignatures, UTCOffset, SessionDate);
			
	Context.Insert("SignatureParameters", SignatureParameters);
	SignatureDate = SignatureParameters.UnverifiedSignatureDate;
	If ValueIsFilled(SignatureDate) Then
		Context.SignatureAdditionResult.SignatureDate = SignatureDate;
	EndIf;
	
	Certificates = New Array;
	If SignatureParameters.CertificateDetails <> Undefined Then
		Certificates.Add(ContainerSignatures.Signatures[0].SignatureCertificate);
	EndIf;

	ChooseFilesAfterGetCertificatesFromSignature(Certificates, Context);
	
EndProcedure

// Continues the SelectFile procedure.
&AtClient
Procedure ChooseFilesAfterGetCertificatesFromSignature(Certificates, Context)
	
	If Certificates.Count() = 0 Then
		ErrorAtClient = New Structure("ErrorDescription",
			NStr("vi = 'Trong tệp chữ ký không có chứng chỉ nào.';
				|ru = 'В файле подписи нет ни одного сертификата.';
				|en = 'The signature file contains no certificates.'; fa = 'The signature file contains no certificates.';
				|it = 'Nel file di firma non vi è alcun certificato.';
				|pl = 'W pliku podpisu nie ma ani jednego certyfikatu.';
				|tr = 'İmza dosyasında hiçbir sertifika bulunmuyor.'"));
		
		AddError(ErrorAtClient, Context);
		Return;
	EndIf;
	
	Try
		If Certificates.Count() = 1 Then
			Certificate = Certificates[0];
		ElsIf Certificates.Count() > 1 Then
			Certificate = DigitalSignatureInternalClientServer.CertificatesInOrderToRoot(Certificates)[0];
		EndIf;
	Except
		ErrorAtClient = New Structure("ErrorDescription",
			ErrorProcessing.BriefErrorDescription(ErrorInfo()));
		AddError(ErrorAtClient, Context);
		Return;
	EndTry;
	
	Context.Insert("Certificate", Certificate);
	
	CurrentCertificate = Context.Certificate; // CryptoCertificate
	CurrentCertificate.BeginUnloading(New CallbackDescription(
		"ChooseFileAfterCertificateExport", ThisObject, Context));
	
EndProcedure

// Continues the SelectFile procedure.
&AtClient
Async Procedure ChooseFileAfterCertificateExport(CertificateData, Context) Export
	
	CertificateProperties = Await DigitalSignatureInternalClient.CertificateProperties(Context.Certificate);
	CertificateProperties.Insert("BinaryData", CertificateData);
	
	SignatureProperties = DigitalSignatureInternalClientServer.SignatureProperties(Context.SignatureAdditionResult.SignatureData,
		CertificateProperties, "", UsersClient.AuthorizedUser(), 
		Context.SignatureAdditionResult.FileName, Context.SignatureParameters, True);
	
	AddRow(ThisObject, Context.AddNewRows, SignatureProperties,
		Context.SignatureAdditionResult.FileName, Context.SignatureAdditionResult.SignaturePropertiesAddress);
	
	SelectFileAfterAddRow(Context);
	
EndProcedure

// Continues the SelectFile procedure.
&AtClient
Procedure SelectFileAfterAddRow(Context)
	
	If Not DataDetails.Property("Data") Or Context.DataToValidateSignature = False Then
		SelectFilesLoopStart(Context);
		Return; // If data is not specified, the signature cannot be checked.
	EndIf;
	
	If Context.DataToValidateSignature = Undefined Then
		DigitalSignatureInternalClient.GetDataFromDataDetails(New CallbackDescription(
			"ChooseFileAfterGetData", ThisObject, Context),
		ThisObject, DataDetails, DataDetails.Data, True);
	Else
		ChooseFileAfterGetData(Context.DataToValidateSignature, Context);
	EndIf;
	
EndProcedure

// Continues the SelectFile procedure.
&AtClient
Procedure ChooseFileAfterGetData(Result, Context) Export
	
	If TypeOf(Result) = Type("Structure") Then
		Context.DataToValidateSignature = False;
		SelectFilesLoopStart(Context);
		Return; // Cannot get data. Signature check is impossible.
	EndIf;
	
	If Context.DataToValidateSignature = Undefined Then
		Context.DataToValidateSignature = Result;
	EndIf;
	
	ParametersForCheck = DigitalSignatureClient.SignatureVerificationParameters();
	ParametersForCheck.ShowCryptoManagerCreationError = False;
	ParametersForCheck.ResultAsStructure = True;
	DigitalSignatureInternalClient.VerifySignature(New CallbackDescription(
			"ChooseFileAfterCheckSignature", ThisObject, Context),
		Context.DataToValidateSignature, Context.SignatureAdditionResult.SignatureData, ,
		Context.SignatureAdditionResult.SignatureDate, ParametersForCheck);
	
EndProcedure

// Continues the SelectFile procedure.
&AtClient
Procedure ChooseFileAfterCheckSignature(CheckResult, Context) Export
	
	If CheckResult.Result = Undefined Then
		SelectFilesLoopStart(Context);
		Return; // Cannot check the signature.
	EndIf;
	
	UpdateCheckSignatureResult(Context.SignatureAdditionResult.SignaturePropertiesAddress, CheckResult);
	SelectFilesLoopStart(Context);
	
EndProcedure

&AtServer
Procedure UpdateCheckSignatureResult(SignaturePropertiesAddress, CheckResult)
	
	CurrentSessionDate = CurrentSessionDate(); 
	
	SignatureProperties = GetFromTempStorage(SignaturePropertiesAddress);
	
	NewSignatureProperties = DigitalSignatureClientServer.NewSignatureProperties();
	FillPropertyValues(NewSignatureProperties, SignatureProperties);
	FillPropertyValues(NewSignatureProperties, CheckResult);
	NewSignatureProperties.SignatureValidationDate = CurrentSessionDate;
	
	PutToTempStorage(NewSignatureProperties, SignaturePropertiesAddress);
	
EndProcedure

&AtServer
Function AddRowsOnServer(PlacedFiles, AddNewRows)
	
	Map = New Map;
	OtherFiles = New Map;
	
	DigitalSignatureLocalization.OnAddRowsAtServer(
		ThisObject, PlacedFiles, OtherFiles, ErrorOnLOAsImport, UUID);
	
	For Each FileThatWasPut In PlacedFiles Do
		
		NameContent = CommonClientServer.ParseFullFileName(FileThatWasPut.Name);
		
		If OtherFiles.Get(NameContent.Name) <> Undefined Then
			Continue;
		EndIf;

		RowAdditionResult = New Structure;

		RowAdditionResult.Insert("Success", False);
		RowAdditionResult.Insert("Address", FileThatWasPut.Location);
		RowAdditionResult.Insert("FileName", NameContent.Name);
		RowAdditionResult.Insert("ErrorAtServer", New Structure);
		RowAdditionResult.Insert("SignatureData", Undefined);
		RowAdditionResult.Insert("SignatureDate", Undefined);
		RowAdditionResult.Insert("SignaturePropertiesAddress", Undefined);
		
		RowAdditionResult = AddRowAtServer(RowAdditionResult, AddNewRows);
		Map.Insert(FileThatWasPut.Name, RowAdditionResult);
		
	EndDo;
	
	Return Map;
	
EndFunction

&AtServer
Function AddRowAtServer(Val RowAdditionResult, AddNewRow)
	
	Try
		RowAdditionResult.SignatureData = DigitalSignature.DERSignature(RowAdditionResult.Address);
	Except
		ErrorInfo = ErrorInfo();
		RowAdditionResult.ErrorAtServer.Insert("ErrorDescription", ErrorProcessing.BriefErrorDescription(ErrorInfo));
		Return RowAdditionResult;
	EndTry;
	
	RowAdditionResult.SignatureDate = DigitalSignature.SigningDate(RowAdditionResult.SignatureData);
	
	If Not DigitalSignature.VerifyDigitalSignaturesOnTheServer()
		And Not DigitalSignature.GenerateDigitalSignaturesAtServer() Then
		
		Return RowAdditionResult;
	EndIf;
	
	CreationParameters = DigitalSignatureInternal.CryptoManagerCreationParameters();
	CreationParameters.ErrorDescription = RowAdditionResult.ErrorAtServer;
	CreationParameters.SignAlgorithm = DigitalSignatureInternalClientServer.GeneratedSignAlgorithm(
		RowAdditionResult.SignatureData);
	
	CryptoManager = DigitalSignatureInternal.CryptoManager("", CreationParameters);
	
	RowAdditionResult.ErrorAtServer = CreationParameters.ErrorDescription;
	If CryptoManager = Undefined Then
		Return RowAdditionResult;
	EndIf;
	
	Try
		ContainerSignatures = CryptoManager.GetCryptoSignaturesContainer(RowAdditionResult.SignatureData);
	Except
		ErrorInfo = ErrorInfo();
		RowAdditionResult.ErrorAtServer.Insert("ErrorDescription", StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Không thể nhận nơi chứa chữ ký từ tệp chữ ký do nguyên nhân:
			|%1';
			|ru = 'Не удалось получить контейнер подписи из файла подписи по причине:
			|%1';
			|en = 'Couldn''t receive the signature container from the signature file due to:
			|%1'; fa = 'Couldn''t receive the signature container from the signature file due to:
			|%1';
			|it = 'Не удалось получить контейнер подписи из файла подписи по причине:
			|%1';
			|pl = 'Couldn''t receive the signature container from the signature file due to:
			|%1';
			|tr = 'İmza dosyasındaki imza konteyneri şu sebeple alınamadı:
			|%1'"),
			ErrorProcessing.BriefErrorDescription(ErrorInfo)));
		Return RowAdditionResult;
	EndTry;
	
	SignatureParameters = DigitalSignatureInternal.ParametersCryptoSignatures(ContainerSignatures,
		DigitalSignatureInternal.UTCOffset(), CurrentSessionDate());
	
	If ValueIsFilled(SignatureParameters.UnverifiedSignatureDate) Then
		RowAdditionResult.SignatureDate = SignatureParameters.UnverifiedSignatureDate;
	EndIf;
	
	CertificateProperties = SignatureParameters.CertificateDetails;
	Certificate = ContainerSignatures.Signatures[0].SignatureCertificate;
	
	CertificateProperties.Insert("BinaryData", Certificate.Unload());
	
	SignatureProperties = DigitalSignatureInternalClientServer.SignatureProperties(RowAdditionResult.SignatureData,
		CertificateProperties, "", Users.AuthorizedUser(), RowAdditionResult.FileName, SignatureParameters, True);
	
	AddRow(ThisObject, AddNewRow, SignatureProperties, RowAdditionResult.FileName,
		RowAdditionResult.SignaturePropertiesAddress);
	RowAdditionResult.Success = True;
	
	Return RowAdditionResult;
	
EndFunction

&AtClientAtServerNoContext
Procedure AddRow(Form, AddNewRow, SignatureProperties, FileName, SignaturePropertiesAddress)
	
	NewSignatureProperties = DigitalSignatureClientServer.NewSignatureProperties();
	FillPropertyValues(NewSignatureProperties, SignatureProperties);
	
	SignaturePropertiesAddress = PutToTempStorage(NewSignatureProperties, Form.UUID);
	
	If AddNewRow Then
		CurrentData = Form.Signatures.Add();
	Else
		CurrentData = Form.Signatures.FindByID(Form.Items.Signatures.CurrentRow);
	EndIf;
	
	CurrentData.PathToFile = FileName;
	CurrentData.SignaturePropertiesAddress = SignaturePropertiesAddress;
	
EndProcedure

&AtServer
Function SignaturesToBeAdded()
	
	Result = New Array;
	For Each Signature In Signatures Do
		SignatureProperties = GetFromTempStorage(Signature.SignaturePropertiesAddress);
		SignatureProperties.Insert("Comment", Signature.Comment);
		Result.Add(PutToTempStorage(SignatureProperties, UUID));
	EndDo;
	
	Return Result;
	
EndFunction

&AtServer
Function AddSignature(ObjectReference, ObjectVersion)
	
	Result = SignaturesToBeAdded();
	DigitalSignature.AddSignature(ObjectReference, Result, UUID, ObjectVersion);
	Return Result;
	
EndFunction

&AtClient
Procedure AddError(ErrorAtClient, Context, AdditionalParameters = Undefined)
	
	If ValueIsFilled(ErrorAtClient.ErrorDescription) Then
		Found4 = Context.Errors.ErrorsAtClient.Get(ErrorAtClient.ErrorDescription);
		If Found4 = Undefined Then
			Found4 = New Structure("Files, AdditionalParameters", New Array);
		EndIf;

		Found4.Files.Add(Context.SignatureAdditionResult.FileName);
		Found4.AdditionalParameters = AdditionalParameters;
		Context.Errors.ErrorsAtClient.Insert(ErrorAtClient.ErrorDescription, Found4);
	EndIf;

	If ValueIsFilled(Context.SignatureAdditionResult.ErrorAtServer) Then
		ErrorAtServer = Context.SignatureAdditionResult.ErrorAtServer;
		If ErrorAtServer.ErrorDescription <> ErrorAtClient.ErrorDescription Then
			Found4 = Context.Errors.ErrorsAtServer.Get(ErrorAtServer.ErrorDescription);
			If Found4 = Undefined Then
				Found4 = New Structure("Files, AdditionalParameters", New Array);
			EndIf;

			Found4.Files.Add(Context.SignatureAdditionResult.FileName);
			Found4.AdditionalParameters = AdditionalParameters;
			Context.Errors.ErrorsAtServer.Insert(ErrorAtServer.ErrorDescription, Found4);
		EndIf;
	EndIf;

	SelectFilesLoopStart(Context);
	
EndProcedure

&AtClient
Procedure ShowError(ErrorAtClient, ErrorAtServer, AdditionalParameters = Undefined)
	
	DigitalSignatureInternalClient.ShowApplicationCallError(
		NStr("vi = 'Không thể nhận chữ ký từ tệp';
			|ru = 'Не удалось получить подпись из файла';
			|en = 'Cannot receive a signature from the file'; fa = 'Cannot receive a signature from the file';
			|it = 'Non è stato possibile ricevere la firma dal file';
			|pl = 'Pobieranie podpisu z pliku nie powiodło się';
			|tr = 'Dosyadan imza alınamadı'"),
		"", ErrorAtClient, ErrorAtServer, AdditionalParameters);
	
EndProcedure

&AtServer
Procedure ImportMRLOAs()
	
	DigitalSignatureLocalization.OnImportMRLOAs(ThisObject);
	
EndProcedure

&AtServer
Procedure FillMRLOAs(SignedObject = Undefined)
	
	DigitalSignatureLocalization.OnFillMRLOAs(ThisObject);
	
EndProcedure

&AtClient
Procedure MRLOASelectFromCatalog()
	
	CurrentData = Items.Signatures.CurrentData;
	CompletionHandler = New CallbackDescription("MRLOAEndOfSelection", ThisObject);
	DigitalSignatureClientLocalization.OnSelectMRLOA(CompletionHandler, CurrentData);
	
EndProcedure

&AtClient
Procedure MRLOAEndOfSelection(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	CurrentData = Items.Signatures.CurrentData;
	CurrentData.MachineReadableLetterOfAuthority = Result;
	SignaturesMRLOAOnChange();
	
EndProcedure

&AtClient
Procedure SignaturesMRLOAOnChange()
	
	If DataDetails.Property("Object") And TypeOf(DataDetails.Object) <> Type("CallbackDescription") Then
		FillMRLOAInRow(Items.Signatures.CurrentRow, DataDetails.Object);
	Else
		FillMRLOAInRow(Items.Signatures.CurrentRow);
	EndIf;
	
EndProcedure

&AtServer
Procedure FillMRLOAInRow(RowID, SignedObject = Undefined)
	
	DigitalSignatureLocalization.OnFillMRLOAInRow(ThisObject, RowID, SignedObject);
		
EndProcedure

&AtClient
Procedure SignaturesMachineReadableLetterOfAuthorityAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	StandardProcessing = False;
EndProcedure

#EndRegion