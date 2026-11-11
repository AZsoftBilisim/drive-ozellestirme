#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	If CommandParameter.IsEmpty() Then
		MessageText = NStr("vi = 'Chưa chỉ ra phiên bản của ứng dụng để kết xuất';
							|ru = 'Не указана версия приложения для выгрузки';
							|en = 'Application version for export is not specified'; fa = 'Application version for export is not specified';
							|it = 'Non è stata specificata la versione dell''applicazione da esportare';
							|pl = 'Nie wskazano wersji aplikacji do przesłania';
							|tr = 'İndirme için uygulama sürümü belirtilmedi'");
		CommonClientServer.MessageToUser(MessageText);
		Return;		
	EndIf;
	
	ExportApplicationToFile(CommandParameter);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
// Uploads the application to the specified file on disk.
//
// Parameters:
//  The Mobile application version is a link to the directory element corresponding to the application
//  that you want to upload.
//
Procedure ExportApplicationToFile(MobileApplicationVersion)
	
	#If Not WebClient Then
		
		ApplicationStructure = ApplicationDescription(MobileApplicationVersion);
		
		If ApplicationStructure.IsFolder Then
			MessageText = NStr("vi = 'Chưa chọn phiên bản ứng dụng để kết xuất';
								|ru = 'Не выбрана версия приложения для выгрузки';
								|en = 'Application version for export is not selected'; fa = 'Application version for export is not selected';
								|it = 'Non è stata scelta la versione dell''applicazione da importare';
								|pl = 'Nie wybrani wersji aplikacji do przesłania';
								|tr = 'İndirme için uygulama sürümü seçilmedi'");
			CommonClientServer.MessageToUser(MessageText);
			Return;
		EndIf;
		
		DialogMode = FileDialogMode.Save;	
		FileDialog = New FileDialog(DialogMode);		
		FileDialog.Title = NStr("vi = 'Hãy chỉ ra tên tệp để kết xuất ứng dụng';
								|ru = 'Укажите имя файла для выгрузки приложения';
								|en = 'Specify a file name to export the application to'; fa = 'Specify a file name to export the application to';
								|it = 'Specificare il nome del file per l''importazione dell''applicazione';
								|pl = 'Wskaż nazwę pliku do przesłania aplikacji';
								|tr = 'Uygulamayı indirmek için dosyanın adını belirt'");
		
		FileDialog.FullFileName = NStr("vi = 'Ứng dụng di động';
										|ru = 'Мобильное приложение';
										|en = 'Mobile application'; fa = 'برنامه موبایل';
										|it = 'Applicazione per dispositivi mobili';
										|pl = 'Aplikacja mobilna';
										|tr = 'Mobil uygulama'")
		    + " "
			+ ApplicationStructure.ApplicationName + NStr("vi = '_Phiên bản';
															|ru = '_Версия';
															|en = '_Version'; fa = '_Version';
															|it = '_Versione';
															|pl = '_Version';
															|tr = '_Sürüm'")
			+ " "
			+ ApplicationStructure.VersionNumber;
			
		FileDialog.DefaultExt = "xml";
		FileDialog.Filter = "xml";
		
		If FileDialog.Choose() Then
			
			FileName = FileDialog.FullFileName;
			
			XMLWriter = New XMLWriter();
			XMLWriter.OpenFile(FileName,"UTF-8");
			XMLWriter.WriteXMLDeclaration();
			
			XMLWriter.WriteStartElement("MobileApplicationVersionData");
			
			XMLWriter.WriteStartElement("ApplicationName");
			XMLWriter.WriteText(ApplicationStructure.ApplicationName);
			XMLWriter.WriteEndElement();
			
			XMLWriter.WriteStartElement("Version");
			XMLWriter.WriteText(ApplicationStructure.VersionNumber);
			XMLWriter.WriteEndElement();
			
			XMLWriter.WriteStartElement("Application");
			XMLWriter.WriteText(ApplicationStructure.Application);
			XMLWriter.WriteEndElement();
			
			XMLWriter.WriteStartElement("Metadata");
			XMLWriter.WriteText(ApplicationStructure.Metadata);
			XMLWriter.WriteEndElement();
			
			XMLWriter.WriteEndElement();
			
			XMLWriter.Close();
			
			MessageText = NStr("vi = 'Ứng dụng đã kết xuất';
								|ru = 'Приложение выгружено';
								|en = 'Application is exported'; fa = 'Application is exported';
								|it = 'Applicazione caricata';
								|pl = 'Aplikacja została przesłana';
								|tr = 'Uygulama indirildi'");
			ShowUserNotification("",,MessageText);
			
		EndIf;
		
	#EndIf
	
EndProcedure

&AtServer
// Retrieves the structure containing the data of the specified application
//
// Parameters:
//  Link - Reference link.Versiymobile applications - link to the directory
//
// Returns:
//  A structure containing application data.
//
Function ApplicationDescription(Ref)
	
	ApplicationStructure = New Structure();
	ApplicationStructure.Insert("IsFolder", Ref.IsFolder);
	
	If ApplicationStructure.IsFolder Then
		Return ApplicationStructure;
	EndIf;
		
	NameOfParent = Common.ObjectAttributeValue(Ref, "Parent.Description");	
	
	ApplicationStructure.Insert("Application", Ref.MobileApplication);
	ApplicationStructure.Insert("ApplicationName", NameOfParent);
	ApplicationStructure.Insert("VersionNumber", Ref.Code);
	ApplicationStructure.Insert("Metadata", Ref.UsedMetadata);
	
	Return ApplicationStructure;
	
EndFunction

#EndRegion