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
	
	SetConditionalAppearance();
	
	InitializationOfFormAttributes();
	
	InitializingFormElements();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	SetCurrentRowOfTable();
	
	If Not Items.WorkOption.Visible Then
		
		WorkOptionOnChange("");
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure WorkOptionOnChange(Item)
	
	If WorkOption = 0 Then
		
		Items.PanelMain.CurrentPage = Items.TransportTypesPageNewSettings;
		Items.GroupCommandBar.CurrentPage = Items.CommandPanelNewSettingsPage;
		
	Else
		
		Items.PanelMain.CurrentPage = Items.TransportTypesPageContinuedSettings;
		Items.GroupCommandBar.CurrentPage = Items.CommandPanelContinuedSettingsPage;

	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersNewSetupTable

&AtClient
Procedure NewSetupTableSelection(Item, RowSelected, Field, StandardProcessing)
	
	If StrFind(Field.Name, "Help") Then
		CurrentData = Items.NewSetupTable.CurrentData;
		OpenHelp(CurrentData.FullNameOfTransportProcessing);
	Else
		Done("");
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersTableContinuedSettings

&AtClient
Procedure TableContinuedSettingsSelection(Item, RowSelected, Field, StandardProcessing)

	CurrentData = Items.TableContinuedSettings.CurrentData;
	
	If StrFind(Field.Name, "Help") Then
		OpenHelp(CurrentData.FullNameOfTransportProcessing);
	Else
		TransportID = CurrentData.TransportID;
		DownloadConnectionSettings("");
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Done(Command)
	
	Result = New Structure;
	
	CurrentData = Items.NewSetupTable.CurrentData;
	
	If CurrentData = Undefined Then
		
		Text = NStr("vi = 'Để tiếp tục tùy chỉnh, hãy chọn một trong các kiểu truyền';
					|ru = 'Для продолжения настройки выберите один из типов транспорта';
					|en = 'To continue, select a transport type'; fa = 'To continue, select a transport type';
					|it = 'Для продолжения настройки выберите один из типов транспорта';
					|pl = 'To continue, select a transport type';
					|tr = 'Kuruluma devam etmek için taşıma türlerinden birini seçin'", 
			CommonClient.DefaultLanguageCode());
		
		CommonClient.MessageToUser(Text);
		
		Return;
		
	EndIf;
	
	TransportID = CurrentData.TransportID;
	
	Result.Insert("TransportID", TransportID);
	Result.Insert("WizardRunOption", WizardRunOption);
	
	Close(Result);
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Close();
	
EndProcedure

&AtClient
Procedure DownloadConnectionSettings(Command)
	
	CurrentData = Items.TableContinuedSettings.CurrentData;
	
	If CurrentData = Undefined Then
		
		Text = NStr("vi = 'Để tiếp tục tùy chỉnh, hãy chọn một trong các kiểu truyền';
					|ru = 'Для продолжения настройки выберите один из типов транспорта';
					|en = 'To continue, select a transport type'; fa = 'To continue, select a transport type';
					|it = 'Для продолжения настройки выберите один из типов транспорта';
					|pl = 'To continue, select a transport type';
					|tr = 'Kuruluma devam etmek için taşıma türlerinden birini seçin'", 
			CommonClient.DefaultLanguageCode());
		
		CommonClient.MessageToUser(Text);
		
		Return;
		
	EndIf;
	
	TransportID = CurrentData.TransportID;

	Notification = New CallbackDescription("EndingSelectionOfSettingsFile", ThisObject);
		
	ImportParameters = FileSystemClient.FileImportParameters();
	ImportParameters.Dialog.Filter = NStr("vi = 'Tệp tùy chỉnh';
											|ru = 'Файл настроек';
											|en = 'Setting file'; fa = 'Setting file';
											|it = 'Файл настроек';
											|pl = 'Setting file';
											|tr = 'Ayar dosyası'") + "|*.json;*.xml";
	ImportParameters.Dialog.Title = NStr("vi = 'Hãy chọn tệp tùy chỉnh';
										|ru = 'Выберите файл настроек';
										|en = 'Select setting file'; fa = 'Select setting file';
										|it = 'Выберите файл настроек';
										|pl = 'Select setting file';
										|tr = 'Ayar dosyasını seçin'");
	
	FileSystemClient.ImportFile_(Notification, ImportParameters);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure SetCurrentRowOfTable()
	
	If IdOfNewRow <> 0
		And Items.NewSetupTable.CheckRow(IdOfNewRow) = True Then
		
		Items.NewSetupTable.CurrentRow = IdOfNewRow;
		
	EndIf;
	
	If RowIDContinued <> 0 
		And Items.TableContinuedSettings.CheckRow(RowIDContinued) = True Then
		
		Items.TableContinuedSettings.CurrentRow = RowIDContinued;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	// NewSetupTable
	Item = ConditionalAppearance.Items.Add();
		
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("NewSetupTableAlias");
			
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("NewSetupTable.Selected");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Font", StyleFonts.DataSynchronizationBoldFont);
	
	// TableContinuedSettings
	Item = ConditionalAppearance.Items.Add();
		
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("TableContinuedSettingsAlias");
			
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TableContinuedSettings.Selected");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
		
	Item.Appearance.SetParameterValue("Font", StyleFonts.DataSynchronizationBoldFont);
	
EndProcedure

&AtServer
Procedure InitializationOfFormAttributes()
	
	If IsBlankString(Parameters.ExchangePlanName) Then
		
		Raise NStr("vi = 'Biểu mẫu này không được dùng để mở trực tiếp.';
					|ru = 'Эта форма не предназначена для непосредственного открытия.';
					|en = 'This is a dependent form and opens from a different form.'; fa = 'This is a dependent form and opens from a different form.';
					|it = 'Эта форма не предназначена для непосредственного открытия.';
					|pl = 'This is a dependent form and opens from a different form.';
					|tr = 'Bu form doğrudan açılmak üzere tasarlanmamıştır.'", 
			Common.DefaultLanguageCode());
		
	EndIf;

	ExchangePlanName = Parameters.ExchangePlanName;
	TransportID = Parameters.TransportID;
	SettingID = Parameters.SettingID;
	WizardRunOption = Parameters.WizardRunOption;
	
	Peer = ExchangePlans[ExchangePlanName].EmptyRef();
	
	Table = ExchangeMessagesTransport.TableOfTransportParameters(Peer, SettingID);
	
	For Each String In Table Do
		
		If Not String.PassiveMode Then
			
			NewRow = NewSetupTable.Add();
			FillPropertyValues(NewRow, String);
			NewRow.PictureHelp = PictureLib.FormHelp;
			
			If String.TransportID = TransportID Then
				NewRow.Selected = True;
				IdOfNewRow = NewRow.GetID();
			EndIf;
			
		EndIf;
		
		If Not String.DirectConnection Then
			
			NewRow = TableContinuedSettings.Add();
			FillPropertyValues(NewRow, String);
			NewRow.PictureHelp = PictureLib.FormHelp;
			
			If String.TransportID = TransportID Then
				NewRow.Selected = True;
				RowIDContinued = NewRow.GetID();
			EndIf;
			
		EndIf;
		
	EndDo;
	
	If WizardRunOption = "ContinueDataExchangeSetup"
		And ExchangePlans.MasterNode() = Undefined Then
		WorkOption = 1;
	EndIf;
	
EndProcedure

&AtServer
Procedure InitializingFormElements()
	
	DIBSetup = DataExchangeCached.IsDistributedInfobaseExchangePlan(ExchangePlanName);
	Items.WorkOption.Visible = Not DIBSetup;
	
	If Items.WorkOption.Visible Then
		
		WorkOption = -1;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure EndingSelectionOfSettingsFile(Result, AdditionalSettings) Export

	If Result = Undefined Then
		Return;
	EndIf;
	
	ErrorMessage = "";
	
	Try

		ConnectionSettings = ReadAndCheckConnectionSettings(Result.Name, Result.Location, ErrorMessage);
	
	Except
		
		BriefErrorDescription = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		Template = NStr("vi = 'Lỗi khi đọc tệp tùy chỉnh. Có thể, đã chỉ ra tệp sai định dạng.
						|%1';
						|ru = 'Ошибка при чтении файла настроек. Возможно, указан файл неправильного формата.
						|%1';
						|en = 'Error reading setting file. Perhaps, the file format is unsupported.
						|%1'; fa = 'Error reading setting file. Perhaps, the file format is unsupported.
						|%1';
						|it = 'Ошибка при чтении файла настроек. Возможно, указан файл неправильного формата.
						|%1';
						|pl = 'Error reading setting file. Perhaps, the file format is unsupported.
						|%1';
						|tr = 'Ayarlar dosyası okunurken hata oluştu. Dosya formatı yanlış olabilir.
						|%1'");
		
		ErrorMessage = StrTemplate(Template, BriefErrorDescription);
		
	EndTry;
	
	If ValueIsFilled(ErrorMessage) Then
		CommonClient.MessageToUser(ErrorMessage); 
		Return;
	EndIf;
	
	Close(ConnectionSettings);
	
EndProcedure

&AtServer
Function ReadAndCheckConnectionSettings(Val SettingsFileName, Val Address, ErrorMessage)
	
	TempFileName = GetTempFileName();
	
	BinaryData = GetFromTempStorage(Address);
	BinaryData.Write(TempFileName);
	
	Read = New TextReader;
	Read.Open(TempFileName);
	Text = Read.Read();
	Read.Close();

	DeleteFiles(TempFileName);
	
	File = New File(SettingsFileName);
	
	If Lower(File.Extension) = ".xml" Then
		ConnectionSettings = ReadAndCheckConnectionSettingsFromXML(Text, ErrorMessage);
	ElsIf Lower(File.Extension) = ".json" Then
		ConnectionSettings = ReadAndCheckConnectionSettingsFromJSON(Text, ErrorMessage);
	Else
		ErrorText = NStr("vi = 'Sai đuôi tệp tùy chỉnh.';
						|ru = 'Неверное расширение файла настроек.';
						|en = 'Invalid setting file extension.'; fa = 'Invalid setting file extension.';
						|it = 'Неверное расширение файла настроек.';
						|pl = 'Invalid setting file extension.';
						|tr = 'Geçersiz ayarlar dosya uzantısı.'",
			Common.DefaultLanguageCode());
		Raise ErrorText;
	EndIf;
	
	Return ConnectionSettings;
	
EndFunction

&AtServer
Function ReadAndCheckConnectionSettingsFromXML(Val XMLText, ErrorMessage)
	
	ConnectionSettings = ExchangeMessagesTransportClientServer.StructureOfConnectionSettings();
	ConnectionSettings.ExchangePlanName = ExchangePlanName;
	ConnectionSettings.WizardRunOption = "ContinueDataExchangeSetup";
	
	ConnectionSettingsFromXML = ExchangeMessagesTransport.ConnectionSettingsFromXML(XMLText, TransportID);
	ExchangeMessagesTransport.CheckAndFillInXMLConnectionSettings(ConnectionSettings, ConnectionSettingsFromXML,, ErrorMessage);
		
	Return ConnectionSettings;
	
EndFunction

&AtServer
Function ReadAndCheckConnectionSettingsFromJSON(Val JSONText, ErrorMessage)
	
	ConnectionSettings = ExchangeMessagesTransportClientServer.StructureOfConnectionSettings();
	ConnectionSettings.ExchangePlanName = ExchangePlanName;
	ConnectionSettings.WizardRunOption = "ContinueDataExchangeSetup";
	
	ConnectionSettingsFromJSON = ExchangeMessagesTransport.ConnectionSettingsFromJSON(JSONText);
	
	ExchangeMessagesTransport.CheckAndFillInXMLConnectionSettings(ConnectionSettings, ConnectionSettingsFromJSON,, ErrorMessage);
	
	Return ConnectionSettings;
	
EndFunction

#EndRegion
