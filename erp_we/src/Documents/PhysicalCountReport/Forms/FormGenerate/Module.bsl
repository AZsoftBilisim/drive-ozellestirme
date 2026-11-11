#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	StartDate			= Undefined;
	EndDate		= Undefined;
	MarkOrganizations	= Undefined;
	
	Parameters.Property("Warehouse",					Warehouse);
	Parameters.Property("StartDate",			StartDate);
	Parameters.Property("EndDate",			EndDate);
	Parameters.Property("MarkOrganizations",	MarkOrganizations);
	
	If ValueIsFilled(StartDate)
		And ValueIsFilled(EndDate) Then
		
		PhysicalInventoryCountPeriod.StartDate		= StartDate;
		PhysicalInventoryCountPeriod.EndDate	= EndDate;
		
	EndIf;
	
	Warehouse				= SettingsValueCached.GetDefaultWarehouse(Warehouse);
	MarkOrganizations = ?(TypeOf(MarkOrganizations) = Type("Array"), MarkOrganizations, New Array);
	
	UseMultipleCompanies		= GetFunctionalOption("UseMultipleCompanies");
	UseManagementCompany	= Constants.UseManagementCompany.Get();
	
	Query = New Query;
	Query.Text = QueryTextTableOrganizations();
	
	Query.SetParameter("MarkOrganizations",					MarkOrganizations);
	Query.SetParameter("UseManagementCompany",	UseManagementCompany);
	Query.SetParameter("Warehouse",									Warehouse);
	Query.SetParameter("StartDate",								PhysicalInventoryCountPeriod.StartDate);
	Query.SetParameter("EndDate",							PhysicalInventoryCountPeriod.EndDate);
	
	QueryResult	= Query.ExecuteBatchWithIntermediateData();
	CompaniesList	= QueryResult[0].Unload().UnloadColumn("Organization");
	
	CompanyTable.Load(QueryResult[QueryResult.UBound()].Unload());
	
	If UseMultipleCompanies Then
		Items.PagesCompanies.CurrentPage = Items.PageSeveralCompanies;
	Else
		Items.PagesCompanies.CurrentPage = Items.PageOneCompany;
		
		If CompaniesList.Count() = 0 Then
			Cancel		= True;
			ErrorText	= NStr("vi = 'Không thể lập bản kiểm kê, vì trong tùy chỉnh chương trình chưa nhập thông tin về doanh nghiệp.';
								|ru = 'Невозможно сформировать инвентаризационную опись, т.к. в настройках программы не введены сведения об организации.';
								|en = 'Cannot generate a physical inventory register as the company information is not entered in the application settings.'; fa = 'Cannot generate a physical inventory register as the company information is not entered in the application settings.';
								|it = 'È impossibile generare l''inventario, perché nelle impostazioni del programma non sono immesse i dati della società.';
								|pl = 'Jest niemożliwe sporządzenie spisu inwentaryzacyjnego, ponieważ w ustawieniach programu nie wprowadzono informacji o firmie.';
								|tr = 'Fiziksel stok kaydı oluşturmak imkansızdır, çünkü uygulama ayarlarında iş yeri bilgisi girilmez.'");
			
			Raise ErrorText;
		EndIf;
		
		If CompanyTable.Count() > 0
			And CompanyTable[0].Required2 Then
			
			Items.PagesDemandSheetCreation.CurrentPage = Items.PageSheetsAreRequired;
			
		Else
			Items.PagesDemandSheetCreation.CurrentPage = Items.PageSheetsAreNotRequired;
		EndIf;
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.CommandBar = Items.Sheets.CommandBar;
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PhysicalInventoryCountPeriodOnChange(Item)
	
	PhysicalInventoryCountPeriodOnChangeServer();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersSheets

&AtClient
Procedure SheetsOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Back(Command)
	
	Notification		= New CallbackDescription("BackCompletion", ThisForm);
	QueryText	= NStr("vi = 'Khi trả lại, tại bước trước đó sẽ xóa các bản kiểm kê đã lập. Tiếp tục?';
						|ru = 'При возврате на предыдущий шаг сформированные инвентаризационные описи будут удалены. Продолжить?';
						|en = 'Generated physical inventory registers will be removed if you return to the previous step. Continue?'; fa = 'Generated physical inventory registers will be removed if you return to the previous step. Continue?';
						|it = 'Quando si torna al passaggio precedente, gli elenchi di inventario generati verranno eliminati. Continuare?';
						|pl = 'Podczas powrotu do poprzedniego kroku sporządzone spisy inwentaryzacyjne zostaną usunięte. Kontynuować?';
						|tr = 'Bir önceki adıma geri dönüldüğünde oluşturulan stok listeleri silinecektir. Devam edilsin mi?'");
	
	ButtonsList = New ValueList;
	ButtonsList.Add("Delete",	NStr("vi = 'Xóa bỏ';
										|ru = 'Удалить';
										|en = 'Delete'; fa = 'حذف';
										|it = 'Eliminare';
										|pl = 'Delete';
										|tr = 'Sil'"));
	ButtonsList.Add("Cancel",		NStr("vi = 'Hủy bỏ';
											|ru = 'Отмена';
											|en = 'Cancel'; fa = 'انصراف';
											|it = 'Annulla';
											|pl = 'Cancel';
											|tr = 'İptal'"));
	
	ShowQueryBox(Notification, QueryText, ButtonsList, , "Cancel");
	
EndProcedure

&AtClient
Procedure Next(Command)
	
	ClearMessages();
	
	HasErrors = False;
	
	If Not ValueIsFilled(PhysicalInventoryCountPeriod.StartDate)
		Or Not ValueIsFilled(PhysicalInventoryCountPeriod.EndDate) Then
		
		HasErrors	= True;
		ErrorText	= NStr("vi = 'Điền kỳ kiểm kê.';
							|ru = 'Заполните период инвентаризации.';
							|en = 'Fill in physical inventory count period.'; fa = 'Fill in physical inventory count period.';
							|it = 'Compilare il periodo di inventario.';
							|pl = 'Wypełnij okres inwentaryzacji.';
							|tr = 'Fiziksel stok sayımı dönemi doldur.'");
		
		CommonClientServer.MessageToUser(ErrorText, , "PhysicalInventoryCountPeriod");
		
	EndIf;
	
	If PhysicalInventoryCountPeriod.StartDate > PhysicalInventoryCountPeriod.EndDate Then
		HasErrors	= True;
		ErrorText	= NStr("vi = 'Điền chính xác kỳ kiểm kê.';
							|ru = 'Заполните корректно период инвентаризации.';
							|en = 'Fill in physical inventory count period correctly.'; fa = 'Fill in physical inventory count period correctly.';
							|it = 'Compilare il periodo di inventario nel modo corretto.';
							|pl = 'Wypełnij poprawnie okres inwentaryzacji.';
							|tr = 'Fiziksel stok sayımı dönemini doğru doldurunuz.'");
		
		CommonClientServer.MessageToUser(ErrorText, , "PhysicalInventoryCountPeriod");
	EndIf;
	
	If Not ValueIsFilled(Warehouse) Then
		HasErrors	= True;
		ErrorText	= NStr("vi = 'Điền Kho bãi.';
							|ru = 'Заполните Склад.';
							|en = 'Fill in Warehouse.'; fa = 'Fill in Warehouse.';
							|it = 'Compilare il Magazzino.';
							|pl = 'Wypełnij Magazyn.';
							|tr = 'Ambarı doldur.'");
		
		CommonClientServer.MessageToUser(ErrorText, , "Warehouse");
	EndIf;
	
	If UseMultipleCompanies Then
		
		SearchSelection				= New Structure("Mark", True);
		MarkedOrganizations	= CompanyTable.FindRows(SearchSelection);
		
		If MarkedOrganizations.Count() = 0 Then
			HasErrors	= True;
			ErrorText	= NStr("vi = 'Hãy chọn một hoặc nhiều doanh nghiệp cần tạo biên bản kiểm kê.';
								|ru = 'Выберите одну или несколько организаций, по которым необходимо создать инвентаризационные описи.';
								|en = 'Select one or several companies for which physical inventory registers should be created.'; fa = 'Select one or several companies for which physical inventory registers should be created.';
								|it = 'Selezionare una o più società per le quali è necessario generare gli elenchi di inventario.';
								|pl = 'Wybierz jedną lub kilka firm, według których należy utworzyć spisy inwentaryzacyjne.';
								|tr = 'Fiziksel stok sayımı oluşturmak istediğiniz bir veya daha fazla iş yerini seç.'");
			
			CommonClientServer.MessageToUser(ErrorText, , "CompanyTable", "Object");
		EndIf;
		
	ElsIf CompanyTable.Count() = 0 Then
		
		HasErrors = True;
		ErrorText = NStr("vi = 'Không có biên bản kho trong kỳ đã chỉ ra mà chưa lập bản kiểm kê, do đó không có nhu cầu trong lập bản kiểm kê.';
						|ru = 'Нет складских актов в указанном периоде, по которым не сформированы описи, поэтому нет потребности в формировании описи.';
						|en = 'There are no inventory adjustments in the specified period for which sheets were not generated, thus there is no need to generate an inventory register.'; fa = 'There are no inventory adjustments in the specified period for which sheets were not generated, thus there is no need to generate an inventory register.';
						|it = 'Non ci sono gli atti di magazzino nel periodo specificato per cui non sono stati generati gli inventari quindi non è richiesto generare gli inventari.';
						|pl = 'Brak aktów magazynowych w danym okresie, dla których nie zostały utworzone spisy, dlatego nie ma potrzeby sporządzania spisu.';
						|tr = 'Belirtilen dönemde stokların oluşturulmadığı herhangi bir stok düzeltmeleri yoktur, bu nedenle stok oluşturmaya gerek yoktur.'");
		
		CommonClientServer.MessageToUser(ErrorText);
		
	Else
		CompanyTable[0].Mark = True;
	EndIf;
	
	If HasErrors Then
		Return;
	EndIf;
	
	HasErrors = HasErrors 
				Or Not NextServer();
	
	If HasErrors Then
		Return;
	Else
		ClearMessages();
	EndIf;
	
EndProcedure

&AtClient
Procedure Done(Command)
	
	Close(CreatedSheetList.UnloadValues());
	
EndProcedure

&AtClient
Procedure ClearAll3(Command)
	
	For Each String In CompanyTable Do
		String.Mark = False;
	EndDo;
	
EndProcedure

&AtClient
Procedure SelectAllCommand(Command)
	
	For Each String In CompanyTable Do
		String.Mark = True;
	EndDo;
	
EndProcedure

&AtClient
Procedure SelectDefaultCompanies(Command)
	
	For Each RowOfTables In CompanyTable Do
		RowOfTables.Mark = RowOfTables.Required2;
	EndDo;
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.Sheets);
	
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.Sheets, Result);
	
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.Sheets);
	
EndProcedure
// End StandardSubsystems.AttachableCommands

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.Sheets);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function NextServer()
	
	CreatedDocuments = CreateDocumentsServer();
	CreatedSheetList.LoadValues(CreatedDocuments);
	
	Sheets.Filter.Items.Clear();
	FilterElement = Sheets.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue = New DataCompositionField("Ref");
	FilterElement.ComparisonType = DataCompositionComparisonType.InList;
	FilterElement.RightValue = CreatedDocuments;
	FilterElement.Use = True;
	
	Items.GroupPages.CurrentPage = Items.GroupPage2;
	Items.ConfirmButton.DefaultButton = True;
		
	Return True;
	
EndFunction

&AtServer
Function CreateDocumentsServer()
	
	CreatedDocuments = New Array;
	
	For Each RowOfTables In CompanyTable Do
		
		If Not RowOfTables.Mark Then
			Continue;
		EndIf;
		
		FillingData = New Structure;
		FillingData.Insert("StartDate",		PhysicalInventoryCountPeriod.StartDate);
		FillingData.Insert("EndDate",	PhysicalInventoryCountPeriod.EndDate);
		FillingData.Insert("Warehouse",			Warehouse);
		FillingData.Insert("Organization",	RowOfTables.Organization);
		
		DocumentObject = Documents.PhysicalCountReport.CreateDocument();
		DocumentObject.Fill(FillingData);
		DocumentObject.Date = PhysicalInventoryCountPeriod.EndDate;
		
		DocumentObject.Write(DocumentWriteMode.Posting);
		CreatedDocuments.Add(DocumentObject.Ref);
		
	EndDo;
	
	Return CreatedDocuments;
	
EndFunction

&AtClient
Procedure BackCompletion(Response, AdditionalParameters) Export
	
	If Response = Undefined
		Or Response = "Cancel" Then
		
		Return;
		
	EndIf;
	
	DeleteDocumentsServer(CreatedSheetList.UnloadValues());
	
	Items.GroupPages.CurrentPage	= Items.GroupPage1;
	Items.NextButton.DefaultButton	= True;
	
EndProcedure

&AtServerNoContext
Procedure DeleteDocumentsServer(CreatedSheetList)
	
	SetPrivilegedMode(True);
	
	For Each DocumentRef In CreatedSheetList Do
		DocumentObject = DocumentRef.GetObject(); // DocumentObject -
		
		DocumentObject.Delete();
	EndDo;
	
EndProcedure

&AtServer
Procedure PhysicalInventoryCountPeriodOnChangeServer()
	
	Query = New Query;
	Query.Text = QueryTextTableOrganizations(False);
	
	Query.SetParameter("CompanyTable",	CompanyTable.Unload());
	Query.SetParameter("Warehouse",				Warehouse);
	Query.SetParameter("StartDate",			PhysicalInventoryCountPeriod.StartDate);
	Query.SetParameter("EndDate",		PhysicalInventoryCountPeriod.EndDate);
	
	CompanyTable.Load(Query.Execute().Unload());
	
EndProcedure

&AtServer
Function QueryTextTableOrganizations(InitializingOrganizationsTable = True)
	
	If InitializingOrganizationsTable Then
		
		QueryTextTTOrganizations = 
		"SELECT ALLOWED
		|	Companies.Ref AS Organization,
		|	CASE
		|		WHEN Companies.Ref IN(&MarkOrganizations)
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS Mark
		|INTO CompanyTable
		|FROM
		|	Catalog.Companies AS Companies
		|WHERE
		|	(NOT &UseManagementCompany
		|			AND NOT Companies.Predefined
		|		OR &UseManagementCompany)";
		
	Else
		
		QueryTextTTOrganizations =
		"SELECT
		|	CompanyTable.Organization	AS Organization,
		|	CompanyTable.Mark		AS Mark
		|INTO CompanyTable
		|FROM
		|	&CompanyTable AS CompanyTable";
		
	EndIf;
	
	QueryText = QueryTextTTOrganizations + Common.QueryBatchSeparator() +
	"SELECT DISTINCT
	|	BEGINOFPERIOD(NestedQuery.Date, DAY)	AS Date,
	|	NestedQuery.Organization					AS Organization
	|INTO OrganizationsFromActs
	|FROM
	|	(SELECT
	|		InventorySurplusRecognition.Date			AS Date,
	|		InventorySurplusRecognition.Organization	AS Organization
	|	FROM
	|		Document.InventorySurplusRecognition AS InventorySurplusRecognition
	|	WHERE
	|		InventorySurplusRecognition.Posted
	|		AND InventorySurplusRecognition.Warehouse = &Warehouse
	|		AND InventorySurplusRecognition.Date BETWEEN &StartDate AND &EndDate
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		GoodsMisgrading.Date			AS Date,
	|		GoodsMisgrading.Organization	AS Organization
	|	FROM
	|		Document.GoodsMisgrading AS GoodsMisgrading
	|	WHERE
	|		GoodsMisgrading.Posted
	|		AND GoodsMisgrading.Warehouse = &Warehouse
	|		AND GoodsMisgrading.Date BETWEEN &StartDate AND &EndDate
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		GoodsDamage.Date			AS Date,
	|		GoodsDamage.Organization	AS Organization
	|	FROM
	|		Document.GoodsDamage AS GoodsDamage
	|	WHERE
	|		GoodsDamage.Posted
	|		AND GoodsDamage.Warehouse = &Warehouse
	|		AND GoodsDamage.Date BETWEEN &StartDate AND &EndDate
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		WriteOffOfGoodsShortages.Date		AS Date,
	|		WriteOffOfGoodsShortages.Organization	AS Organization
	|	FROM
	|		Document.WriteOffOfGoodsShortages AS WriteOffOfGoodsShortages
	|	WHERE
	|		WriteOffOfGoodsShortages.Posted
	|		AND WriteOffOfGoodsShortages.Warehouse = &Warehouse
	|		AND WriteOffOfGoodsShortages.Date BETWEEN &StartDate AND &EndDate) AS NestedQuery
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	CompanyTable.Organization	AS Organization,
	|	CompanyTable.Mark		AS Mark,
	|	CASE
	|		WHEN OrganizationsFromActs.Organization IS NULL
	|			THEN FALSE
	|		ELSE TRUE
	|	END							AS Required2
	|FROM
	|	CompanyTable AS CompanyTable
	|		LEFT JOIN OrganizationsFromActs AS OrganizationsFromActs
	|		ON CompanyTable.Organization = OrganizationsFromActs.Organization
	|		
	|		LEFT JOIN Document.PhysicalCountReport AS PhysicalCountReport
	|		ON PhysicalCountReport.Posted
	|			AND OrganizationsFromActs.Organization = PhysicalCountReport.Organization
	|			AND PhysicalCountReport.Warehouse = &Warehouse
	|			AND OrganizationsFromActs.Date BETWEEN PhysicalCountReport.StartDate AND PhysicalCountReport.EndDate
	|
	|WHERE
	|	PhysicalCountReport.Ref IS NULL
	|
	|ORDER BY
	|	Mark DESC,
	|	CompanyTable.Organization";
	
	Return QueryText;
	
EndFunction

#EndRegion
