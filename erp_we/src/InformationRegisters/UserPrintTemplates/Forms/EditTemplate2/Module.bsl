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
	
	If Parameters.SpreadsheetDocument <> Undefined Then
		TemplateToChange = Parameters.SpreadsheetDocument;
	EndIf;
	
	TemplateMetadataObjectName = Parameters.TemplateMetadataObjectName;
	DataSources.LoadValues(PrintManagement.TemplateDataSource(TemplateMetadataObjectName));
	NameParts = StrSplit(TemplateMetadataObjectName, ".");
	TemplateName = NameParts[NameParts.UBound()];
	
	OwnerName = "";
	For PartNumber = 0 To NameParts.UBound()-1 Do
		If Not IsBlankString(OwnerName) Then
			OwnerName = OwnerName + ".";
		EndIf;
		OwnerName = OwnerName + NameParts[PartNumber];
	EndDo;
	
	TemplateType = Parameters.TemplateType;
	TemplatePresentation = TemplatePresentation();
	TemplateFileName = CommonClientServer.ReplaceProhibitedCharsInFileName(TemplatePresentation) + "." + Lower(TemplateType);
	
	If Parameters.OpenOnly Then
		Title = NStr("vi = 'Mở khuôn mẫu in';
					|ru = 'Открытие макета печатной формы';
					|en = 'Open print form template'; fa = 'Open print form template';
					|it = 'Aprire il layout di stampa';
					|pl = 'Otwieranie szablony formularzy wydruku';
					|tr = 'Yazdırma formu şablonunu aç'");
	EndIf;
	
	ClientType = ?(Common.IsWebClient(), "", "Not") + "WebClient";
	
	If Not Common.IsWebClient() And Not Common.IsMobileClient() And TemplateType = "MXL" Then
		Items.ApplyChangesLabelNotWebClient.Title = NStr(
			"vi = 'Sau khi đưa các thay đổi cần thiết vào khuôn in, hãy nhấn nút ""Kết thúc thay đổi""';
			|ru = 'После внесения необходимых изменений в макет нажмите на кнопку ""Завершить изменение""';
			|en = 'Once you finish editing the template, click Apply changes'; fa = 'Once you finish editing the template, click Apply changes';
			|it = 'Dopo aver apportato le modifiche necessarie al layout, clicca sul pulsante ""Completa la modifica""';
			|pl = 'Po podaniu niezbędnych zmian w szablonie, kliknij przycisk ""Zakończ zmianę""';
			|tr = 'Şablonda değişiklik yaptıktan sonra ""Sonlandırmayı düzenle"" i tıklayın.'");
	EndIf;
	
	SetApplicationNameForTemplateOpening();
	
	Items.Dialog.CurrentPage = Items["DownloadToComputerPage" + ClientType];
	Items.CommandBar.CurrentPage = Items.DownloadBar;
	Items.ChangeButton.DefaultButton = True;
	
	If Common.IsMobileClient() Then 
		ClientType = "MobileClient";
	EndIf;
	WindowOptionsKey = ClientType + Upper(TemplateType);
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
#If Not WebClient And Not MobileClient Then
		If Parameters.OpenOnly Then
			Cancel = True;
		EndIf;
		If Parameters.OpenOnly Or TemplateType = "MXL" Then
			OpenTemplate();
		EndIf;
#EndIf
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Not IsBlankString(TempDirectoryName) Then
		BeginDeletingFiles(New CallbackDescription, TempDirectoryName);
	EndIf;
	
	If Exit Then
		Return;
	EndIf;
	
	EventName = "CancelTemplateChange";
	If TemplateImported Then
		EventName = "Write_UserPrintTemplates";
	EndIf;
	
	NotificationParameters = StandardSubsystemsClient.NewNotificationParameterForSpreadsheetDocumentWrite();
	NotificationParameters.TemplateMetadataObjectName = TemplateMetadataObjectName;
	NotificationParameters.DataSources = DataSources.UnloadValues();
	
	Notify(EventName, NotificationParameters, ThisObject);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure LinkToApplicationPageClick(Item)
	FileSystemClient.OpenURL(TemplateOpeningApplicationAddress);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Change(Command)
	OpenTemplate();
	If Parameters.OpenOnly Then
		Close();
	EndIf;
EndProcedure

&AtClient
Procedure ExitAppUpdate(Command)
	
#If WebClient Or MobileClient Then
		CallbackDescription = New CallbackDescription("OnImportFile", ThisObject);
		ImportParameters = FileSystemClient.FileImportParameters();
		ImportParameters.FormIdentifier = UUID;
		FileSystemClient.ImportFile_(CallbackDescription, ImportParameters);
#Else
		If Lower(TemplateType) = "mxl" Then
			TemplateToChange.Hide();
			TemplateFileAddressInTemporaryStorage = PutToTempStorage(TemplateToChange);
			TemplateImported = True;
		Else
			File = New File(PathToTemplateFile);
			If File.Exists() Then
				BinaryData = New BinaryData(PathToTemplateFile);
				TemplateFileAddressInTemporaryStorage = PutToTempStorage(BinaryData);
				TemplateImported = True;
			EndIf;
		EndIf;
		WriteTemplateAndClose();
#EndIf
	
EndProcedure


&AtClient
Procedure Cancel(Command)
	Close();
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetApplicationNameForTemplateOpening()
	
	ApplicationNameForTemplateOpening = "";
	
	FileType = Lower(TemplateType);
	If FileType = "mxl" Then
		ApplicationNameForTemplateOpening = NStr("vi = '""1С:DOANH NGHIỆP -Làm việc với tệp""';
												|ru = '1С:Предприятие - Работа с файлами';
												|en = '1C:Enterprise. File management'; fa = '1C:Enterprise. File management';
												|it = '1С:Предприятие - Работа с файлами';
												|pl = '1C:Enterprise. File management';
												|tr = '1C:Enterprise - Dosya Yönetimi'");
		TemplateOpeningApplicationAddress = "http://v8.1c.ru/metod/fileworkshop.htm";
	ElsIf FileType = "doc" Then
		ApplicationNameForTemplateOpening = NStr("vi = 'Microsoft Word';
												|ru = 'Microsoft Word';
												|en = 'Microsoft Word'; fa = 'Microsoft Word';
												|it = 'Microsoft Word';
												|pl = 'Microsoft Word';
												|tr = 'Microsoft Word'");
		TemplateOpeningApplicationAddress = "http://office.microsoft.com/ru-ru/word";
	ElsIf FileType = "odt" Then
		ApplicationNameForTemplateOpening = NStr("vi = 'OpenOffice Writer';
												|ru = 'OpenOffice Writer';
												|en = 'OpenOffice Writer'; fa = 'OpenOffice Writer';
												|it = 'OpenOffice Writer';
												|pl = 'OpenOffice Writer';
												|tr = 'OpenOffice Writer'");
		TemplateOpeningApplicationAddress = "http://www.openoffice.org/product/writer.html";
	ElsIf FileType = "docx" Then
		ApplicationNameForTemplateOpening = NStr("vi = 'một trong các gói văn phòng hoặc bộ soạn chứng từ định dạng Office Open XML';
												|ru = 'один из офисных пакетов или редактор документов формата Office Open XML';
												|en = 'any editors that support Office Open XML documents'; fa = 'any editors that support Office Open XML documents';
												|it = 'una delle suite per ufficio o l''editor di documenti Office Open XML';
												|pl = 'jeden z pakietów biurowych lub edytor dokumentów formatu Office Open XML';
												|tr = 'Ofis paketlerinden biri veya Office Open XML belge düzenleyicisi'");
		TemplateOpeningApplicationAddress = "";
	EndIf;
	
	NavigateToAppPage = NStr("vi = 'Chuyển đến trang web %1 để cài đặt';
							|ru = 'Перейти на веб-страницу %1 для установки';
							|en = 'Open %1 installation web page'; fa = 'Open %1 installation web page';
							|it = 'Перейти на веб-страницу %1 для установки';
							|pl = 'Open %1 installation web page';
							|tr = 'Yapılandırma için %1 web sayfasına git'");
	NavigateToAppPage = StringFunctionsClientServer.SubstituteParametersToString(NavigateToAppPage, ApplicationNameForTemplateOpening);
	Items.LinkToApplicationPageBeforeDownloadWebClient.Title = NavigateToAppPage;
	Items.LinkToApplicationPageBeforeDownloadNotWebClient.Title = NavigateToAppPage;
	Items.LinkToApplyChangesApplicationPageWebClient.Title = NavigateToAppPage;
	Items.LinkToApplyChangesApplicationPageNotWebClient.Title = NavigateToAppPage;
	
	Items.BeforeDownloadTemplateInstructionWebClientLabel.Title = 
		NStr("vi = 'Hãy nhấn nút ""Tiếp tục"" để bắt đầu kết nhập.';
			|ru = 'Нажмите на кнопку ""Продолжить"", чтобы начать загрузку.';
			|en = 'Click Continue to import.'; fa = 'برای ورود اطلاعات، ادامه را کلیک کنید.';
			|it = 'Fate il clic sul pulsante ""Continuare"" per cominciare il caricamento.';
			|pl = 'Kliknij przycisk ""Kontynuuj"", aby rozpocząć pobieranie.';
			|tr = 'İçe aktarımı başlatmak için ""Devam et""e tıklayın.'");
	Items.BeforeDownloadTemplateInstructionNotWebClientLabel.Title = 
		NStr("vi = 'Hãy nhấn nút ""Tiếp tục"" để mở khuôn in trong ứng dụng khác. Hãy thay đổi khuôn in, đóng lại và làm theo hướng dẫn.';
			|ru = 'Нажмите на кнопку ""Продолжить"" для открытия макета в другом приложении. Внесите в макет изменения, закройте его и следуйте дальнейшим инструкциям.';
			|en = 'Click Continue to open the template in another application. Modify the template, close it, and follow further instructions.'; fa = 'برای بازکردن الگو در برنامه دیگر، ادامه را کلیک کنید. الگو را تغییر دهید، آن را ببندید و دستورالعمل‌های بعدی را دنبال کنید.';
			|it = 'Нажмите на кнопку ""Продолжить"" для открытия макета в другом приложении. Внесите в макет изменения, закройте его и следуйте дальнейшим инструкциям.';
			|pl = 'Click Continue to open the template in another application. Modify the template, close it, and follow further instructions.';
			|tr = 'Şablonu başka uygulamada açmak için ""Devam et""e basın. Şablonu değiştirip kapatın ve sonraki talimatları takip edin.'");
	
	If Parameters.OpenOnly Then
		Items.BeforeDownloadTemplateApplicationWebClientLabel.Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Tệp khuôn in ""%1"" đã soạn để kết nhập vào máy tính và để mở bằng ứng dụng khác.
				 |
				 |Nếu vẫn chưa cài đặt ứng dụng để soạn thì nên cài đặt %2.';
				 |ru = 'Файл макета ""%1"" подготовлен для загрузки на компьютер и открытия с помощью другого приложения.
				 |
				 |Если приложение для редактирования еще не установлено, рекомендуется установить %2.';
				 |en = 'Template file ""%1"" is ready to be imported and opened with an external application on your computer.
				 |
				 |If you haven''t installed the editor yet, we recommend installing %2.'; fa = 'Template file ""%1"" is ready to be imported and opened with an external application on your computer.
				 |
				 |If you haven''t installed the editor yet, we recommend installing %2.';
				 |it = 'Файл макета ""%1"" подготовлен для загрузки на компьютер и открытия с помощью другого приложения.
				 |
				 |Если приложение для редактирования еще не установлено, рекомендуется установить %2.';
				 |pl = 'Template file ""%1"" is ready to be imported and opened with an external application on your computer.
				 |
				 |If you haven''t installed the editor yet, we recommend installing %2.';
				 |tr = '""%1"" şablon dosyası, ve %3 diğer uygulama kullanılarak bilgisayara içe aktarılmaya hazırlanıyor. 
				 |
				 |Eğer düzenleme uygulaması henüz yüklü değilse, ""%2"" yüklenmesi önerilir.'"), TemplatePresentation,
				ApplicationNameForTemplateOpening);
	Else
		Items.BeforeDownloadTemplateApplicationWebClientLabel.Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Tệp khuôn in ""%1"" đã soạn để kết nhập vào máy tính và để nhập các thay đổi bằng ứng dụng khác.
				 |
				 |Nếu vẫn chưa cài đặt ứng dụng để soạn thì nên cài đặt %2.';
				 |ru = 'Файл макета ""%1"" подготовлен для загрузки на компьютер и внесения изменений с помощью другого приложения.
				 |
				 |Если приложение для редактирования еще не установлено, рекомендуется установить %2.';
				 |en = 'Template file ""%1"" is ready to be imported and edited with an external application on your computer.
				 |
				 |If you haven''t installed the editor yet, we recommend installing %2.'; fa = 'Template file ""%1"" is ready to be imported and edited with an external application on your computer.
				 |
				 |If you haven''t installed the editor yet, we recommend installing %2.';
				 |it = 'Файл макета ""%1"" подготовлен для загрузки на компьютер и внесения изменений с помощью другого приложения.
				 |
				 |Если приложение для редактирования еще не установлено, рекомендуется установить %2.';
				 |pl = 'Template file ""%1"" is ready to be imported and edited with an external application on your computer.
				 |
				 |If you haven''t installed the editor yet, we recommend installing %2.';
				 |tr = '''%1'' düzen dosyası bilgisayarınıza indirilmeye ve başka bir uygulama kullanılarak düzenlenmeye hazır.
				 |
				 |Halihazırda yüklü bir düzenleme uygulamanız yoksa, yüklemeniz önerilir.'"), TemplatePresentation,
				ApplicationNameForTemplateOpening);
	EndIf;
	
	Items.BeforeDownloadTemplateApplicationNotWebClientLabel.Title = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Tệp khuôn in ""%1"" đã soạn để nhập các thay đổi bằng ứng dụng khác. Nếu vẫn chưa cài đặt ứng dụng để soạn thì nên cài đặt %2.';
			|ru = 'Файл макета ""%1"" подготовлен для внесения изменений с помощью другого приложения. Если приложение для редактирования еще не установлено, рекомендуется установить %2.';
			|en = 'Template file ""%1"" is ready to be edited with an external application. If you haven''t installed the editor yet, we recommend installing %2.'; fa = 'فایل الگوی «%1» آماده ویرایش با یک برنامه خارجی است. اگر هنوز ویرایشگر را نصب نکرده‌اید، توصیه می‌کنیم %2 را نصب کنید.';
			|it = 'Файл макета ""%1"" подготовлен для внесения изменений с помощью другого приложения. Если приложение для редактирования еще не установлено, рекомендуется установить %2.';
			|pl = 'Template file ""%1"" is ready to be edited with an external application. If you haven''t installed the editor yet, we recommend installing %2.';
			|tr = '""%1"" şablon dosyası, diğer uygulama kullanılarak düzenlenmeye hazır. Eğer düzenleme uygulaması henüz yüklü değilse, ""%2"" yüklenmesi önerilir.'"), 
		TemplatePresentation, ApplicationNameForTemplateOpening);
	
	Items.ApplyChangesLabelWebClient.Title = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Chờ kết thúc kết nhập tệp khuôn in, sau đó mở tệp và chỉnh sửa.
			 |
			 |Sau khi kết thúc soạn, đóng tệp khuôn in và xác nhận thay đổi. Tiếp theo, nhấn nút ""Kết thúc thay đổi"" và chọn tệp này trong hộp thoại tiếp theo.
			 |
			 |Nếu vẫn chưa cài đặt ứng dụng soạn thì nên cài đặt %1.';
			 |ru = 'Дождитесь окончания загрузки файла макета, затем откройте и отредактируйте его.
			 |
			 |После завершения редактирования, закройте файл макета, подтвердив изменения. Затем нажмите на кнопку ""Завершить изменение"" и выберите этот файл в следующем диалоге.
			 |
			 |Если приложение для редактирования еще не установлено, рекомендуется установить %1.';
			 |en = 'Please wait for the template file to be imported, then open and edit it.
			 |
			 |After editing, confirm the changes and close the template file. Then click ""Apply changes"" and select this file in the next dialog box.
			 |
			 |If you haven''t installed the editor yet, we recommend installing %1.'; fa = 'Please wait for the template file to be imported, then open and edit it.
			 |
			 |After editing, confirm the changes and close the template file. Then click ""Apply changes"" and select this file in the next dialog box.
			 |
			 |If you haven''t installed the editor yet, we recommend installing %1.';
			 |it = 'Дождитесь окончания загрузки файла макета, затем откройте и отредактируйте его.
			 |
			 |После завершения редактирования, закройте файл макета, подтвердив изменения. Затем нажмите на кнопку ""Завершить изменение"" и выберите этот файл в следующем диалоге.
			 |
			 |Если приложение для редактирования еще не установлено, рекомендуется установить %1.';
			 |pl = 'Please wait for the template file to be imported, then open and edit it.
			 |
			 |After editing, confirm the changes and close the template file. Then click ""Apply changes"" and select this file in the next dialog box.
			 |
			 |If you haven''t installed the editor yet, we recommend installing %1.';
			 |tr = 'Şablon dosyasının içe aktarılmasını bekleyin, ardından dosyayı açın ve düzenleyin.
			 |
			 |Düzenleme tamamlandığında, değişiklikleri onaylayıp şablon dosyasını kapatın. Ardından ""Değişiklikleri uygula"" butonuna tıklayın ve bir sonraki iletişim kutusunda bu dosyayı seçin. 
			 |
			 |Düzenleme uygulaması yüklü değilse ""%2"" uygulamasını yüklemeniz önerilir.'"), ApplicationNameForTemplateOpening);
	
	Items.ApplyChangesLabelNotWebClient.Title = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Hãy chờ mở khuôn in trong ứng dụng để soạn.
	    	 |
			 |Tiếp theo kết thúc soạn, hãy đóng khuôn in sau khi xác nhận thay đổi. Sau đó nhấn nút ""Kết thúc thay đổi"".
			 |
			 |Nếu vẫn chưa cài đặt ứng dụng để soạn thì nên cài đặt %1.';
			 |ru = 'Дождитесь открытия макета в приложении для редактирования.
			 |
			 |После завершения редактирования, закройте макет, подтвердив изменения. Затем нажмите на кнопку ""Завершить изменение"".
			 |
			 |Если приложение для редактирования еще не установлено, рекомендуется установить %1.';
			 |en = 'Please wait for the template to be opened in the editor.
			 |
			 |After editing, confirm the changes and close the template. Then click ""Apply changes"".
			 |
			 |If you haven''t installed the editor yet, we recommend installing %1.'; fa = 'Please wait for the template to be opened in the editor.
	    	 |
	    	 |After editing, confirm the changes and close the template. Then click ""Apply changes"".
	    	 |
	    	 |If you haven''t installed the editor yet, we recommend installing %1.';
			 |it = 'Дождитесь открытия макета в приложении для редактирования.
			 |
			 |После завершения редактирования, закройте макет, подтвердив изменения. Затем нажмите на кнопку ""Завершить изменение"".
			 |
			 |Если приложение для редактирования еще не установлено, рекомендуется установить %1.';
			 |pl = 'Please wait for the template to be opened in the editor.
			 |
			 |After editing, confirm the changes and close the template. Then click ""Apply changes"".
			 |
			 |If you haven''t installed the editor yet, we recommend installing %1.';
			 |tr = 'Düzenleme için uygulamada şablon açılıncaya kadar bekleyin.
			 |
			 | Düzenleme tamamlandığında, değişiklikleri onaylayarak şablonu kapatın. Ardından, Değişikliği tamamla''yı tıklayın.
			 |
			 | Düzenleme için uygulama henüz yüklü değilse, ""%2"" öğesinin yüklenmesi önerilir.'"), ApplicationNameForTemplateOpening);
		
	LinkToAplicationPageVisibility = (Common.IsWebClient() Or FileType <> "mxl") And FileType <> "docx";
	Items.LinkToApplicationPageBeforeDownloadWebClient.Visible = LinkToAplicationPageVisibility;
	Items.LinkToApplicationPageBeforeDownloadNotWebClient.Visible = LinkToAplicationPageVisibility;
	Items.LinkToApplyChangesApplicationPageWebClient.Visible = LinkToAplicationPageVisibility;
	Items.LinkToApplyChangesApplicationPageNotWebClient.Visible = LinkToAplicationPageVisibility;
	
	Items.BeforeDownloadTemplateApplicationNotWebClientLabel.Visible = FileType <> "mxl";
	
	Items.DownloadToComputerPageWebClient.Visible = Common.IsWebClient();
	Items.UploadToInfobaseWebClientPage.Visible = Common.IsWebClient();
	Items.DownloadToComputerPageNotWebClient.Visible = Not Common.IsWebClient();
	Items.UploadToInfobaseNotWebClientPage.Visible = Not Common.IsWebClient();
	
EndProcedure

&AtServer
Function TemplatePresentation()
	
	Result = TemplateName;
	
	Owner = Common.MetadataObjectByFullName(OwnerName);
	If Owner <> Undefined Then
		Template = Owner.Templates.Find(TemplateName);
		If Template <> Undefined Then
			Result = Template.Synonym;
		EndIf;
	EndIf;
	
	Return Result;
	
EndFunction

&AtClient
Procedure OpenTemplate()
#If WebClient Or MobileClient Then
		OpenWebClientTemplate();
#Else
		OpenThinClientTemplate();
#EndIf
EndProcedure

&AtClient
Procedure OpenThinClientTemplate()
	
	CallbackDescription = New CallbackDescription("OpenTemplateThinClientAfterCreateTempDirectory", ThisObject);
	FileSystemClient.CreateTemporaryDirectory(CallbackDescription);
	
EndProcedure

&AtClient
Procedure OpenTemplateThinClientAfterCreateTempDirectory(TempDirectoryName, AdditionalParameters) Export
	
#If Not WebClient And Not MobileClient Then
	Template = PrintFormTemplate(TemplateMetadataObjectName);
	PathToTemplateFile = CommonClientServer.AddLastPathSeparator(TempDirectoryName) + TemplateFileName;
	
	If TemplateType = "MXL" Then
		If Parameters.OpenOnly Then
			Template.ReadOnly = True;
			Template.Show(TemplatePresentation,,True);
		Else
			Template.Write(PathToTemplateFile);
			Template.Show(TemplatePresentation, PathToTemplateFile, True);
			
			TemplateToChange = Template;
		EndIf;
	Else
		Template.Write(PathToTemplateFile);
		If Parameters.OpenOnly Then
			TemplateFile = New File(PathToTemplateFile);
			TemplateFile.SetReadOnly(True);
		EndIf;
		FileSystemClient.OpenFile(PathToTemplateFile);
	EndIf;
	
	GoToApplyChanges();
#EndIf
	
EndProcedure

&AtClient
Procedure OpenWebClientTemplate()
	FileSystemClient.SaveFile(Undefined, PutTemplateInTempStorage(), TemplateFileName);
	GoToApplyChanges();
EndProcedure

&AtServer
Function PutTemplateInTempStorage()
	
	Return PutToTempStorage(BinaryTemplateData(), UUID);
	
EndFunction

&AtServer
Function BinaryTemplateData()
	
	TemplateData1 = TemplateToChange;
	If TemplateToChange.TableHeight = 0 Then
		TemplateData1 = PrintManagement.PrintFormTemplate(TemplateMetadataObjectName);
	EndIf;
	
	If TypeOf(TemplateData1) = Type("SpreadsheetDocument") Then
		TempFileName = GetTempFileName();
		TemplateData1.Write(TempFileName);
		TemplateData1 = New BinaryData(TempFileName);
		DeleteFiles(TempFileName);
	EndIf;
	
	Return TemplateData1;
	
EndFunction

&AtClient
Procedure GoToApplyChanges()
	Items.Dialog.CurrentPage = Items["UploadToInfobasePage" + ClientType];
	Items.CommandBar.CurrentPage = Items.ApplyChangesPanel;
	Items.FinishButtonUpdate.DefaultButton = True;
EndProcedure

&AtServer
Function TemplateFromTempStorage()
	Template = GetFromTempStorage(TemplateFileAddressInTemporaryStorage); // SpreadsheetDocument, BinaryData 
	If Lower(TemplateType) = "mxl" And TypeOf(Template) <> Type("SpreadsheetDocument") Then
		TempFileName = GetTempFileName();
		Template.Write(TempFileName);
		SpreadsheetDocument = New SpreadsheetDocument;
		SpreadsheetDocument.Read(TempFileName);
		Template = SpreadsheetDocument;
		DeleteFiles(TempFileName);
	EndIf;
	Return Template;
EndFunction

&AtServer
Procedure WriteTemplate(Template)
	Record = InformationRegisters.UserPrintTemplates.CreateRecordManager();
	Record.Object = OwnerName;
	Record.TemplateName = TemplateName;
	Record.Use = True;
	Record.Template = New ValueStorage(Template, New Deflation(9));
	Record.Write();
EndProcedure

&AtServerNoContext
Function PrintFormTemplate(TemplateMetadataObjectName)
	
	Template = PrintManagement.PrintFormTemplate(TemplateMetadataObjectName);
	If TypeOf(Template) = Type("SpreadsheetDocument") Or TypeOf(Template) = Type("BinaryData") Then
		Return Template;
	EndIf;
	
	Raise NStr("vi = 'Không cho phép mở khuôn in này để xem hoặc chỉnh sửa.';
				|ru = 'Открытие данного макета для просмотра или редактирования не предусмотрено.';
				|en = 'Cannot open this template for viewing or editing.'; fa = 'Cannot open this template for viewing or editing.';
				|it = 'Non è prevista l''apertura di questo modello per la visualizzazione o modifica.';
				|pl = 'Otwarcie tej makiety do przeglądu lub edycji nie jest przewidziane.';
				|tr = 'Bu şablon, görüntüleme veya düzenleme için açılamaz.'");
	
EndFunction

&AtClient
Procedure OnImportFile(File, AdditionalParameters) Export
	
	TemplateImported = File <> Undefined;
	If TemplateImported Then
		TemplateFileAddressInTemporaryStorage = File.Location;
		TemplateFileName = File.Name;
	EndIf;
	
	WriteTemplateAndClose();
	
EndProcedure

&AtClient
Procedure WriteTemplateAndClose()
	Template = Undefined;
	If TemplateImported Then
		Template = TemplateFromTempStorage();
		If Not ValueIsFilled(Parameters.SpreadsheetDocument) Then
			WriteTemplate(Template);
		EndIf;
	EndIf;
	
	Close(Template);
EndProcedure

#EndRegion
