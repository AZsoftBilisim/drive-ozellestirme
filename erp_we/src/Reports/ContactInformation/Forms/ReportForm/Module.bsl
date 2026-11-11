

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If Parameters.Property("CommandParameter") Then
		
		SelectionList = New ValueList;
		SelectionList.LoadValues(Parameters.CommandParameter);
		
		Parameters.ListOfCallParameters = SelectionList;
		
	EndIf;
	
	FillTablesOfSelectedFields();
	
	UsePartnersAsCounterparties =  GetFunctionalOption("UsePartnersAsCounterparties");
	
	If (Parameters.Property("GroupByPartner") And Parameters.GroupByPartner = True)
		Or Parameters.VariantKey = "ByContactPersons" Then
		
		Title = NStr("vi = 'Thông tin liên hệ của người liên hệ';
					|ru = 'Контактная информация контактных лиц';
					|en = 'Contact details of contact persons'; fa = 'Contact details of contact persons';
					|it = 'Contatti';
					|pl = 'Dane kontaktowe osób kontaktowych';
					|tr = 'İlgili kişilerin iletişim bilgileri'");
		GroupByPartner = True;
		Items.SelectedPartnerFields.Visible = False;
		
	ElsIf UsePartnersAsCounterparties Then
		
		Title = NStr("vi = 'Thông tin liên hệ theo đối tác';
					|ru = 'Контактная информация по контрагентам';
					|en = 'Contact details by counterparties'; fa = 'Contact details by counterparties';
					|it = 'Informazioni di contatto per le contraenti';
					|pl = 'Informacje kontaktowe na temat kontrahentów';
					|tr = 'Cari hesapla ilgili iletişim bilgileri'");
		
	EndIf;
	
	If UsePartnersAsCounterparties Then
		PartnersAndCounterparties.HeaderOfPropsDependingOnFOUsePartnersAsCounterparties(
		                                 ThisObject, "ReportSettings", NStr("vi = 'Lọc theo đối tác';
																			|ru = 'Отбор по контрагентам';
																			|en = 'Filter by counterparties'; fa = 'Filter by counterparties';
																			|it = 'Selezione per contraente';
																			|pl = 'Filtr wg kontrahentów';
																			|tr = 'Cari hesaba göre filtre'"));
		PartnersAndCounterparties.HeaderOfPropsDependingOnFOUsePartnersAsCounterparties(
		                                 ThisObject, "SelectedPartnerFieldsCheck", NStr("vi = 'Thông tin về đối tác';
																						|ru = 'Информация о контрагенте';
																						|en = 'Counterparty information'; fa = 'Counterparty information';
																						|it = 'Informazioni sul contraente';
																						|pl = 'Informacje dotyczące kontrahenta';
																						|tr = 'Cari hesap bilgileri'"));
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtServer
Procedure OnSaveDataInSettingsAtServer(Settings)
	
	If Not ParameterCall Then
		
		Settings = New Structure;
		Settings.Insert("Filter_Settings",Report.SettingsComposer.GetSettings());
		
		Common.CommonSettingsStorageSave("Report.ContactInformation", "ReportForm", Settings);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure OnLoadVariantAtServer(Settings)
	
	SchemeForUserFilter = Reports.ContactInformation.GetTemplate("FilterByPartners");
	SchemaURL = PutToTempStorage(SchemeForUserFilter,UUID);
	Report.SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(SchemaURL)); 
	
	SettingsValue = Common.CommonSettingsStorageLoad("Report.ContactInformation", "ReportForm");
	
	If Not Parameters.ListOfCallParameters.Count() > 0 Then
		
		If SettingsValue <> Undefined And SettingsValue.Filter_Settings <> Undefined Then
			Report.SettingsComposer.LoadSettings(SettingsValue.Filter_Settings);
			Report.SettingsComposer.Refresh(DataCompositionSettingsRefreshMethod.CheckAvailability);
		EndIf;
		
		FilterPresentation = String(Report.SettingsComposer.Settings.Filter);
		
	Else
		
		ParameterCall = True;
		Report.SettingsComposer.Settings.Filter.Items.Clear();
		
		If TypeOf(Parameters.ListOfCallParameters[0].Value) = Type("CatalogRef.Partners") Then
			CommonClientServer.SetFilterItem(Report.SettingsComposer.Settings.Filter,"Partner", Parameters.ListOfCallParameters, DataCompositionComparisonType.InList);
		ElsIf TypeOf(Parameters.ListOfCallParameters[0].Value) = Type("CatalogRef.BusinessRegions") Then
			CommonClientServer.SetFilterItem(Report.SettingsComposer.Settings.Filter, "BusinessRegion", Parameters.ListOfCallParameters, DataCompositionComparisonType.InList);
		ElsIf TypeOf(Parameters.ListOfCallParameters[0].Value) = Type("CatalogRef.PartnersSegments") Then
			CommonClientServer.SetFilterItem(Report.SettingsComposer.Settings.Filter, "Segment", Parameters.ListOfCallParameters, DataCompositionComparisonType.InList);
		EndIf;
		
		FilterPresentation = String(Report.SettingsComposer.Settings.Filter);
		
		GenerationOnParameterCall = True;
		Cancel = SelectionsFilledInCorrectly(ThisForm);
	
		If Not Cancel Then
			GenerateReportServer();
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "ChangingSettings_ContactInformationReport" Then
		FilterPresentation = Parameter;
		SettingsChanged = True;
		SetStateReportNotGenerated();
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	If Settings.Get("FilterVisibility") <> Undefined Then
		FilterVisibility = Settings.Get("FilterVisibility");
		Items.ReportSettingsGroup.Visible = FilterVisibility;
		Items.ShowHideFilter.Title = ?(FilterVisibility, NStr("vi = 'Ẩn tùy chỉnh';
																|ru = 'Скрыть настройки';
																|en = 'Hide settings'; fa = 'پنهان‌کردن تنظیمات';
																|it = 'Nascondere le impostazioni';
																|pl = 'Ukryj ustawienia';
																|tr = 'Ayarları gizle'"), NStr("vi = 'Hiển thị tùy chỉnh';
																							|ru = 'Показать настройки';
																							|en = 'Show settings'; fa = 'نمایش تنظیمات';
																							|it = 'Mostrare le impostazioni';
																							|pl = 'Pokaż ustawienia';
																							|tr = 'Ayarları göster'"));
	EndIf;
	
	ProcessTablePartSettings(Settings, "SelectedPartnerFields");
	ProcessTablePartSettings(Settings, "SelectedCICP");
	ProcessTablePartSettings(Settings, "CPRoles");

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CheckOnChange(Item)
	
	SetStateReportNotGenerated();
	
EndProcedure 

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ShowHideFilter(Command)
	
	FilterVisibility = Not FilterVisibility;
	Items.ReportSettingsGroup.Visible = FilterVisibility;
	Items.ShowHideFilter.Title = ?(FilterVisibility, NStr("vi = 'Ẩn tùy chỉnh';
															|ru = 'Скрыть настройки';
															|en = 'Hide settings'; fa = 'پنهان‌کردن تنظیمات';
															|it = 'Nascondere le impostazioni';
															|pl = 'Ukryj ustawienia';
															|tr = 'Ayarları gizle'"), NStr("vi = 'Hiển thị tùy chỉnh';
																						|ru = 'Показать настройки';
																						|en = 'Show settings'; fa = 'نمایش تنظیمات';
																						|it = 'Mostrare le impostazioni';
																						|pl = 'Pokaż ustawienia';
																						|tr = 'Ayarları göster'"));
	
EndProcedure

&AtClient
Procedure SelectAll_2(Command)
	
	If Command.Name = "SelectedKICKLeelectAll" Then
		
		TableName = "SelectedCICP";
		
	ElsIf Command.Name = "SelectedPartnerFieldsSelectAllFields" Then
		
		TableName = "SelectedPartnerFields";
		
	ElsIf Command.Name = "RolesOfClselectAll" Then
		
		TableName = "CPRoles";
		
	EndIf;
	
	SetFlagValue(True,ThisForm[TableName]);
	SetStateReportNotGenerated();
	
EndProcedure

&AtClient
Procedure DisableAll(Command)
	
	If Command.Name = "SelectedKicklistExcludeAll" Then
		
		TableName = "SelectedCICP";
		
	ElsIf Command.Name = "SelectedPartnerFieldsExcludeAll" Then
		
		TableName = "SelectedPartnerFields";
		
	ElsIf Command.Name = "RolesClickclickAll" Then
		
		TableName = "CPRoles";
		
	EndIf;
	
	SetFlagValue(False,ThisForm[TableName]);
	SetStateReportNotGenerated();
	
EndProcedure

&AtClient
Procedure GenerateReport(Command)
	
	ClearMessages();
	Cancel = SelectionsFilledInCorrectly(ThisForm);
	
	If Not Cancel Then
		GenerateReportServer();
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtClientAtServerNoContext
Function SelectionsFilledInCorrectly(Form)

	Cancel = False;
	
	NumberOfSelectedCycles  = Form.SelectedCICP.FindRows(New Structure("Check",True)).Count();
	NumberOfSelectedRoles = Form.CPRoles.FindRows(New Structure("Check",True)).Count();
	MessageSelectedKICKLES   = NStr("vi = 'Cần chọn ít nhất một dạng thông tin liên hệ của người liên hệ';
									|ru = 'Необходимо выбрать хотя бы один вид контактной информации контактного лица';
									|en = 'Select at least one contact details kind of contact person'; fa = 'Select at least one contact details kind of contact person';
									|it = 'È necessario scegliere almeno un tipo di informazione di contatto della persona di contatto';
									|pl = 'Musisz wybrać co najmniej jeden typ informacji kontaktowych dla osoby kontaktowej';
									|tr = 'İrtibat kişisi için en az bir iletişim bilgisi türü seçmeniz gerekmektedir'");
	MessageSelectedRoles   = NStr("vi = 'Cần chọn ít nhất một vai trò người liên hệ';
									|ru = 'Необходимо выбрать хотя бы одну роль контактного лица';
									|en = 'Select at least one role of a contact person'; fa = 'Select at least one role of a contact person';
									|it = 'È necessario scegliere almeno un ruolo della persona di contatto';
									|pl = 'Musisz wybrać co najmniej jedną rolę dla osoby kontaktowej';
									|tr = 'İrtibat kişinin en az bir rolünü seçmeniz gerekmektedir'");
	
	If NumberOfSelectedCycles = 0 And NumberOfSelectedRoles = 0 Then
		
		If Form.GroupByPartner Then
			
			Cancel = True;
			CommonClientServer.MessageToUser(MessageSelectedKICKLES,,"SelectedCICP");
			CommonClientServer.MessageToUser(MessageSelectedRoles,,"CPRoles");
			
		EndIf;
		
	ElsIf NumberOfSelectedCycles > 0 And NumberOfSelectedRoles = 0 Then
		
		Cancel = True;
		CommonClientServer.MessageToUser(MessageSelectedRoles,,"CPRoles");
		
	ElsIf NumberOfSelectedCycles = 0 And NumberOfSelectedRoles > 0 Then
		
		Cancel = True;
		CommonClientServer.MessageToUser(MessageSelectedKICKLES,,"SelectedCICP");
		
	EndIf;
	
	Return Cancel;
	
EndFunction

&AtServer
Procedure GenerateReportServer()
	
	ReportTable.Clear();
	ObjectReport = FormAttributeToValue("Report");
	If GenerationOnParameterCall Then
		
		NumberOfSelectedCycles  = SelectedCICP.FindRows(New Structure("Check",True)).Count();
		NumberOfSelectedRoles = CPRoles.FindRows(New Structure("Check",True)).Count();
		
		If NumberOfSelectedCycles = 0 And NumberOfSelectedRoles = 0 And GroupByPartner Then
			SetFlagValue(True,SelectedCICP);
			SetFlagValue(True,CPRoles);
		EndIf;
		
		GenerationOnParameterCall = False;
		
	EndIf;
	ObjectReport.GenerateReport(ReportTable,StructureReportGenerationParameters());
	Items.Result.StatePresentation.Visible = False;
	Items.Result.StatePresentation.AdditionalShowMode = AdditionalShowMode.DontUse;
	ResultReportTable.Clear();
	ResultReportTable.Put(ReportTable);
	
EndProcedure

&AtServer
Function StructureReportGenerationParameters()
	
	ParametersStructure = New Structure();
	
	ParametersStructure.Insert("SelectedPartnerFields",FormAttributeToValue("SelectedPartnerFields"));
	ParametersStructure.Insert("SelectedCICP",FormAttributeToValue("SelectedCICP"));
	ParametersStructure.Insert("CPRoles",FormAttributeToValue("CPRoles"));
	ParametersStructure.Insert("GroupByPartner",GroupByPartner);
	ParametersStructure.Insert("FilterPresentation",FilterPresentation);
	
	Return ParametersStructure;
	
EndFunction

&AtServer
Function NewTableRow(Table,Presentation,Value)
	
	NewRow = Table.Add();
	NewRow.Presentation = Presentation;
	NewRow.Value      = Value;
	
	Return NewRow;
	
EndFunction

&AtClientAtServerNoContext
Procedure SetFlagValue(CheckValue,Table)
	
	For Each Item In Table Do
	
		Item.Check = CheckValue;
	
	EndDo;
	
EndProcedure

&AtServer
Procedure FillTablesOfSelectedFields()
	
	NewTableRow(SelectedPartnerFields, NStr("vi = 'Tên gọi công khai';
											|ru = 'Публичное наименование';
											|en = 'Public name'; fa = 'نام عمومی';
											|it = 'Nome pubblico';
											|pl = 'Nazwa publiczna';
											|tr = 'Kamu adı'"), "DescriptionFull");
	If GetFunctionalOption("UseBusinessRegions") Then
		 NewTableRow(SelectedPartnerFields, NStr("vi = 'Khu vực kinh doanh';
												|ru = 'Бизнес-регион';
												|en = 'Business region'; fa = 'منطقه تجاری';
												|it = 'Regione commerciale';
												|pl = 'Business region';
												|tr = 'İş bölgesi'"), "BusinessRegion");
	EndIf;
	NewTableRow(SelectedPartnerFields, NStr("vi = 'Người quản lý chính';
											|ru = 'Основной менеджер';
											|en = 'Employee in charge'; fa = 'کارمند مسئول';
											|it = 'Manager principale';
											|pl = 'Główny menedżer';
											|tr = 'Ana yönetici'"), "MainManager");
	NewTableRow(SelectedPartnerFields, NStr("vi = 'Ngày ghi nhận';
											|ru = 'Дата регистрации';
											|en = 'Registration date'; fa = 'تاریخ ثبت';
											|it = 'Data di registrazione';
											|pl = 'Data rejestracji';
											|tr = 'Kayıt tarihi'"), "RegistrationDate");
	If AccessRight("View", Metadata.InformationRegisters.ABCXYZCustomerClassification) Then
		NewTableRow(SelectedPartnerFields, NStr("vi = 'Phân loại ABC\XYZ';
												|ru = 'ABC\XYZ классификация';
												|en = 'ABC\XYZ classification'; fa = 'ABC\XYZ classification';
												|it = 'Classificazione ABC\XYZ';
												|pl = 'ABC\XYZ klasyfikacja';
												|tr = 'ABC\XYZ sınıflandırması'"), "Classification");
	EndIf;
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	ContactInformationKinds.Presentation,
	|	ContactInformationKinds.Ref AS Ref,
	|	ContactInformationKinds.Type
	|FROM
	|	Catalog.ContactInformationKinds AS ContactInformationKinds
	|WHERE
	|	ContactInformationKinds.Parent = VALUE(Catalog.ContactInformationKinds.CatalogPartners)
	|	AND NOT ContactInformationKinds.DeletionMark
	|
	|ORDER BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ContactInformationKinds.Presentation,
	|	ContactInformationKinds.Ref AS Ref,
	|	ContactInformationKinds.Type
	|FROM
	|	Catalog.ContactInformationKinds AS ContactInformationKinds
	|WHERE
	|	ContactInformationKinds.Parent = VALUE(Catalog.ContactInformationKinds.CatalogContactPersonsForPartners)
	|	AND NOT ContactInformationKinds.DeletionMark
	|
	|ORDER BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RolesOfPartnerContactPersons.Ref,
	|	RolesOfPartnerContactPersons.Presentation AS Presentation
	|FROM
	|	Catalog.RolesOfPartnerContactPersons AS RolesOfPartnerContactPersons
	|WHERE
	|	NOT RolesOfPartnerContactPersons.DeletionMark
	|
	|ORDER BY
	|	Presentation";
	
	QueryResultsArray1 = Query.ExecuteBatch();
	
	RequestResultPartnerCITypes = QueryResultsArray1[0]; // QueryResult 
	QueryResultTypesOfKikL       = QueryResultsArray1[1]; // QueryResult
	RequestResultForCLRole         = QueryResultsArray1[2]; // QueryResult  
	
	SelectionOfPartnerCITypes = RequestResultPartnerCITypes.Select();
	SamplingTypesOfKIKL       = QueryResultTypesOfKikL.Select();
	SelectingCLRole         = RequestResultForCLRole.Select();
	
	While SelectionOfPartnerCITypes.Next() Do
	
		NewTableRow(SelectedPartnerFields, SelectionOfPartnerCITypes.Presentation, SelectionOfPartnerCITypes.Ref);
	
	EndDo;
	
	Items.SelectedPartnerFields.HeightInTableRows = SelectedPartnerFields.Count() + 1;
	
	While SamplingTypesOfKIKL.Next() Do
		
		NewTableRow(SelectedCICP, SamplingTypesOfKIKL.Presentation, SamplingTypesOfKIKL.Ref);
		
	EndDo;
	
	Items.SelectedCICP.HeightInTableRows = SelectedCICP.Count() + 1;
	
	NewTableRow(CPRoles, NStr("vi = '<Chưa chỉ ra vai trò>';
								|ru = '<Роль не указана>';
								|en = '<Role is not specified>'; fa = '<Role is not specified>';
								|it = '<ruolo non specificato>';
								|pl = '<Rola nie została określona>';
								|tr = '<Rol belirtilmedi>'"), Catalogs.RolesOfPartnerContactPersons.EmptyRef());
	
	While SelectingCLRole.Next() Do
		
		NewTableRow(CPRoles, SelectingCLRole.Presentation, SelectingCLRole.Ref);
		
	EndDo;
	
	Items.CPRoles.HeightInTableRows = CPRoles.Count() + 1;

EndProcedure

&AtClient
Procedure SetStateReportNotGenerated()
	
	Items.Result.StatePresentation.AdditionalShowMode = AdditionalShowMode.Irrelevance;
	Items.Result.StatePresentation.Text = NStr("vi = 'Chưa lập báo cáo. Hãy nhấn nút ""Lập báo cáo"" để nhận báo cáo.';
												|ru = 'Отчет не сформирован. Нажмите ""Сформировать"" для получения отчета.';
												|en = 'Report is not generated. To generate the report, click ""Generate"".'; fa = 'Report is not generated. To generate the report, click ""Generate"".';
												|it = 'Il report non è stato creato. Fate clic su ""Crea"" per ricevere il rapporto.';
												|pl = 'Raport nie został wygenerowany. Kliknij ""Utwórz"", aby wygenerować raport.';
												|tr = 'Rapor oluşturulmadı. Raporu oluşturmak için ""Oluştur"" butonuna tıklayın.'");
	Items.Result.StatePresentation.Visible = True;
	
EndProcedure

&AtServer
Procedure ProcessTablePartSettings(Settings, TableName)
	
	If Settings.Get(TableName) <> Undefined Then
		
		For Each SettingsString In Settings.Get(TableName) Do
			
			If SettingsString.Check Then
				
				FoundRows = ThisForm[TableName].FindRows(New Structure("Value",SettingsString.Value));
				If FoundRows.Count() <> 0 Then
					FoundRows[0].Check = True;
				EndIf;
				
			EndIf;
			
		EndDo;
		
		Settings.Delete(TableName);
		
	EndIf;
	
EndProcedure

#EndRegion
