#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	ItemsAndDimensionsSelectionParameters = Documents.RDExpenseRecognition.ItemsAndDimensionsSelectionParameters(BusinessOperation);
	IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	InitializeDocument();
	
	If TypeOf(FillingData) = Type("Structure") Then
		If FillingData.Property("TopicsStages") Then
			For Each TopicStage In FillingData.TopicsStages Do
				NewRow = RDTopicsStages.Add();
				NewRow.TopicStage = TopicStage;
			EndDo;
		EndIf;
	EndIf;
	
EndProcedure

Procedure OnCopy(CopiedObject)

	InitializeDocument();
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
		
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	ItemsAndDimensionsSelectionParameters = Documents.RDExpenseRecognition.ItemsAndDimensionsSelectionParameters(BusinessOperation);
	IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	If WriteMode = DocumentWriteMode.Posting Then
		TMCommonUse.FillInDocumentIDs(ThisObject, "Allocation")
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	CheckRelevanceOfClosingTopicOfStage(Cancel);
	
	If Not Cancel Then
		
		DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
		CreateTaskForEndOfMonth();
		
	EndIf;
	
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	CreateTaskForEndOfMonth();
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	CheckDistributionDetails(Cancel, CheckedAttributes);
	
	ItemsAndDimensionsSelectionParameters = Documents.RDExpenseRecognition.ItemsAndDimensionsSelectionParameters(BusinessOperation);
	IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, ItemsAndDimensionsSelectionParameters);
	
EndProcedure

#EndRegion

#Region Private

Function GetVerifiableDistributionDetails()
	
	ComplAccountingIsUsed = GetFunctionalOption("UseLocal");
	
	VerifiableDistributionDetails = New ValueTree;
	VerifiableDistributionDetails.Columns.Add("AttributeName", New TypeDescription("String"));
	VerifiableDistributionDetails.Columns.Add("Presentation", New TypeDescription("String"));
	VerifiableDistributionDetails.Columns.Add("DontCheck", New TypeDescription("Boolean"));
	
	PaymentDetailsExpenseType = VerifiableDistributionDetails.Rows.Add();
	PaymentDetailsExpenseType.AttributeName = "ExpenseRecognitionTypeAC";
	PaymentDetailsExpenseType.Presentation = NStr("vi = 'Dạng ghi nhận KTDN';
													|ru = 'Вид признания БУ';
													|en = 'Recognition type LA'; fa = 'Recognition type LA';
													|it = 'Tipo di registrazione Contabilità';
													|pl = 'Rodzaj uznania EK';
													|tr = 'BU tanıma türü'");
	
	ArticleDetails_ = PaymentDetailsExpenseType.Rows.Add();
	ArticleDetails_.AttributeName = "ExpenseItemAccounting";
	ArticleDetails_.Presentation = NStr("vi = 'Dạng chi phí KTDN';
										|ru = 'Статья расходов БУ';
										|en = 'Expense item LA'; fa = 'قلم هزینه (محلی)';
										|it = 'Voce di spese Contabilità Generale';
										|pl = 'Rodzaj kosztu EK';
										|tr = 'Gider kalemi LA'");
	
	AnalyticsDetails = ArticleDetails_.Rows.Add();
	AnalyticsDetails.AttributeName = "ExpensesDimensionAccounting";
	AnalyticsDetails.Presentation = NStr("vi = 'Đối tượng phân tích chi phí KTDN';
										|ru = 'Аналитика расходов БУ';
										|en = 'Expense dimension LA'; fa = 'بُعد هزینه (محلی)';
										|it = 'Analitica di spese Contabilità ordinaria';
										|pl = 'Analityka rozchodów EK';
										|tr = 'Gider boyutu AC'");
	
	PaymentDetailsExpenseType = VerifiableDistributionDetails.Rows.Add();
	PaymentDetailsExpenseType.AttributeName = "ExpenseRecognitionTypeMA";
	PaymentDetailsExpenseType.Presentation = NStr("vi = 'Dạng ghi nhận KTQT';
													|ru = 'Вид признания УУ';
													|en = 'Recognition type MA'; fa = 'Recognition type MA';
													|it = 'Tipo di registrazione Contabilità Gestionale';
													|pl = 'Rodzaj uznania EZ';
													|tr = 'UU''nun tanınma türü'");
	PaymentDetailsExpenseType.DontCheck = True;
	
	ArticleDetails_ = PaymentDetailsExpenseType.Rows.Add();
	ArticleDetails_.AttributeName = "ExpenseItemManagementAccounting";
	ArticleDetails_.Presentation = NStr("vi = 'Dạng chi phí KTQT';
										|ru = 'Статья расходов УУ';
										|en = 'Expense item MA'; fa = 'قلم هزینه (مدیریت)';
										|it = 'Voce di spese Contabilità gestionale';
										|pl = 'Rodzaj kosztu EZ';
										|tr = 'Gider kalemi YM'");
	
	AnalyticsDetails = ArticleDetails_.Rows.Add();
	AnalyticsDetails.AttributeName = "ExpensesDimensionManagementAccounting";
	AnalyticsDetails.Presentation = NStr("vi = 'Đối tượng phân tích chi phí KTQT';
										|ru = 'Аналитика расходов УУ';
										|en = 'Expense dimension MA'; fa = 'بُعد هزینه (مدیریت)';
										|it = 'Analitica di spese Contabilità Gestionale';
										|pl = 'Analiza rozchodów EZ';
										|tr = 'Yönetim muhasebesi gider boyutu'");
	
	If BusinessOperation = Enums.BusinessTransactions.CompletionOfResearchAndDevelopmentStages
		And ComplAccountingIsUsed Then
		
		PaymentDetailsExpenseType = VerifiableDistributionDetails.Rows.Add();
		PaymentDetailsExpenseType.AttributeName = "ExpenseRecognitionTypeTA";
		PaymentDetailsExpenseType.Presentation = NStr("vi = 'Dạng ghi nhận KTTh';
														|ru = 'Вид признания НУ';
														|en = 'Recognition type TA'; fa = 'Recognition type TA';
														|it = 'Tipo di registrazione Contabilità Fiscale';
														|pl = 'Rodzaj uznania EP';
														|tr = 'NU tanıma türü'");
		
		ArticleDetails_ = PaymentDetailsExpenseType.Rows.Add();
		ArticleDetails_.AttributeName = "ExpenseItemTaxAccounting";
		ArticleDetails_.Presentation = NStr("vi = 'Dạng chi phí KTTh';
											|ru = 'Статья расходов НУ';
											|en = 'Expense item TA'; fa = 'قلم هزینه (مالیاتی)';
											|it = 'Voce di spese Contabilità Fiscale';
											|pl = 'Rodzaj kosztu EP';
											|tr = 'Gider kalemi VM'");
		
		AnalyticsDetails = ArticleDetails_.Rows.Add();
		AnalyticsDetails.AttributeName = "ExpensesDimensionTaxAccounting";
		AnalyticsDetails.Presentation = NStr("vi = 'Đối tượng phân tích chi phí KTTh';
											|ru = 'Аналитика расходов НУ';
											|en = 'Expense dimension TA'; fa = 'بُعد هزینه (مالیاتی)';
											|it = 'Analitica di spese Contabilità fiscale';
											|pl = 'Analityka rozchodów EP';
											|tr = 'Gider boyutu VM'");

	EndIf;
	
	Return VerifiableDistributionDetails;
	
EndFunction

Function MandatoryArticles()
	
	ArrayOfArticles = New Array();
	CommonClientServer.SupplementArray(ArrayOfArticles, Allocation.UnloadColumn("ExpenseItemAccounting"));
	CommonClientServer.SupplementArray(ArrayOfArticles, Allocation.UnloadColumn("ExpenseItemTaxAccounting"));
	CommonClientServer.SupplementArray(ArrayOfArticles, Allocation.UnloadColumn("ExpenseItemManagementAccounting"));
	ArrayOfArticles = CommonClientServer.CollapseArray(ArrayOfArticles);
	
	Query = New Query(
	"SELECT
	|	ARTICLES__.Ref AS Ref
	|FROM
	|	ChartOfCharacteristicTypes.ExpenseItems AS ARTICLES__
	|WHERE
	|	ARTICLES__.Ref IN (&ArrayOfArticles)
	|	AND ARTICLES__.ControlDimensionFilling");
	
	Query.SetParameter("ArrayOfArticles", ArrayOfArticles);
	
	Return Query.Execute().Unload().UnloadColumn("Ref");
	
EndFunction

Procedure CheckDistributionDetails(Cancel, CheckedAttributes)
	
	DistributionWithoutPartitioning = False;
	If AdditionalProperties.Property("DistributionWithoutPartitioning")
		And AdditionalProperties.DistributionWithoutPartitioning Then
		DistributionWithoutPartitioning = True;
	EndIf;
	
	VerifiableDistributionDetails = GetVerifiableDistributionDetails();
	MandatoryArticles = MandatoryArticles();
	For Each TableRow In Allocation Do
			
		ValidationErrors = New Structure;
		
		For Each GroupOfVerifiedBankingDetails In VerifiableDistributionDetails.Rows Do
			
			If ValueIsFilled(TableRow[GroupOfVerifiedBankingDetails.AttributeName])
					And TableRow[GroupOfVerifiedBankingDetails.AttributeName] 
						<> Enums.RDExpenseRecognitionTypes.DoNotRecognizeExpenses Then
				
				For Each ArticleDetails_ In GroupOfVerifiedBankingDetails.Rows Do
					If ValueIsFilled(TableRow[ArticleDetails_.AttributeName]) Then
						If Not (MandatoryArticles.Find(TableRow[ArticleDetails_.AttributeName]) = Undefined) Then
							For Each AnalyticsDetails In ArticleDetails_.Rows Do
								If Not ValueIsFilled(TableRow[AnalyticsDetails.AttributeName]) Then
									ValidationErrors.Insert(AnalyticsDetails.AttributeName, AnalyticsDetails.Presentation);
								EndIf;
							EndDo;
						EndIf;
					Else
						ValidationErrors.Insert(ArticleDetails_.AttributeName, ArticleDetails_.Presentation);
					EndIf;
				EndDo;
				
			ElsIf Not ValueIsFilled(TableRow[GroupOfVerifiedBankingDetails.AttributeName])
				And GroupOfVerifiedBankingDetails.DontCheck = False Then	
				ValidationErrors.Insert(GroupOfVerifiedBankingDetails.AttributeName, GroupOfVerifiedBankingDetails.Presentation);
			EndIf;
		EndDo;
		
		For Each CheckError In ValidationErrors Do
			
			ErrorText = "";
			Field = "";
			DataKey = Undefined;
			
			If DistributionWithoutPartitioning Then
				ErrorText = StrTemplate(NStr("vi = 'Chưa điền trường ""%1""';
											|ru = 'Не заполнено поле ""%1""';
											|en = 'Field %1 is required.'; fa = 'Field %1 is required.';
											|it = 'Il campo ""%1"" non è compilato';
											|pl = 'Nie wypełniono pola ""%1""';
											|tr = '""%1"" alanı doldurulmadı'"), CheckError.Value);
				Field = "Items.StageCompletionDistribution.CurrentData." + CheckError.Key;
			Else
				ErrorText = StrTemplate(NStr("vi = 'Trường ""%1"" trong hàng %2 của danh sách ""%3"" không được điền';
											|ru = 'Не заполнено поле ""%1"" в строке %2 списка ""%3""';
											|en = 'Fill in the ""%1"" field in the line %2 of the ""%3"" list'; fa = 'Fill in the ""%1"" field in the line %2 of the ""%3"" list';
											|it = 'Il campo ""%1"" nella riga ""%2"" dell''elenco ""%3"" non è compilato';
											|pl = 'Nie zostało wypełnione pole ""%1"" w wierszu %2 listy ""%3""';
											|tr = '""%3"" listesinin %2 satırındaki ""%1"" alanı doldurulmadı'"),
					CheckError.Value, TableRow.LineNumber, "Attribution ofexpenses");
				Field = CommonClientServer.PathToTabularSection("Allocation", TableRow.LineNumber, CheckError.Key);
				DataKey = ThisObject;
			EndIf;
			
			Common.MessageToUser(
				ErrorText,
				DataKey,
				Field,
				,
				Cancel);
		EndDo;
		
	EndDo;

EndProcedure

Procedure InitializeDocument()
	
	Date = BegOfDay(CurrentSessionDate());
	EmployeeResponsible = Users.CurrentUser();
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	
EndProcedure

Procedure CheckRelevanceOfClosingTopicOfStage(Cancel)
	
	Query = New Query;
	Query.Text =
		"SELECT
		|	RDExpenseRecognitionRDTopicsStages.TopicStage AS TopicStage,
		|	RDExpenseRecognitionRDTopicsStages.Ref AS CompletionDocument
		|FROM
		|	Document.RDExpenseRecognition.RDTopicsStages AS
		|		RDExpenseRecognitionRDTopicsStages
		|WHERE
		|	RDExpenseRecognitionRDTopicsStages.Ref.Date
		|		BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|	AND
		|		RDExpenseRecognitionRDTopicsStages.Ref.BusinessOperation = &BusinessOperation
		|	AND RDExpenseRecognitionRDTopicsStages.Ref.Organization = &Organization
		|	AND RDExpenseRecognitionRDTopicsStages.Ref.Posted
		|	AND RDExpenseRecognitionRDTopicsStages.Ref <> &CurrentDocument
		|	AND RDExpenseRecognitionRDTopicsStages.TopicStage IN (&TopicsStages)
		|GROUP BY
		|	RDExpenseRecognitionRDTopicsStages.TopicStage,
		|	RDExpenseRecognitionRDTopicsStages.Ref";
	
	Query.SetParameter("CurrentDocument", Ref);
	Query.SetParameter("BeginOfPeriod", BegOfMonth(Date));
	Query.SetParameter("EndOfPeriod", EndOfMonth(Date));
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("TopicsStages", RDTopicsStages.UnloadColumn("TopicStage"));
	Query.SetParameter("BusinessOperation", BusinessOperation);
	
	QueryResult = Query.Execute();
	
	If Not QueryResult.IsEmpty() Then
		
		Cancel = True;
		
		SelectionDetailRecords = QueryResult.Select();

		While SelectionDetailRecords.Next() Do
			
			MessageText = NStr("vi = 'Đối với %1 trong kỳ này đã nhập chứng từ %2. Cần hủy kết chuyển chứng từ trước đó';
								|ru = 'Для %1 в данном периоде уже введен документ %2. Необходимо отменить проведение предыдущего документа';
								|en = 'The document %2 has already been entered for %1 in this period. Cancel posting of the previous document'; fa = 'The document %2 has already been entered for %1 in this period. Cancel posting of the previous document';
								|it = 'Per %1 è già stato inserito il documento %2 in questo periodo. è necessario annullare la registrazione del documento precedente';
								|pl = 'Dla %1 w bieżącym okresie jest już zatwierdzony dokument %2. Należy anulować zatwierdzenie poprzedniego dokumentu';
								|tr = 'Bu dönemde %1 için %2 belgesi zaten girilmiştir. Önceki belgenin yürütülmesini iptal etmek gerekir'");
			Common.MessageToUser(
				StrTemplate(MessageText, SelectionDetailRecords.TopicStage, SelectionDetailRecords.CompletionDocument)
				,,,,Cancel);
			
		EndDo;
	EndIf;
	
EndProcedure

Procedure CreateTaskForEndOfMonth()

	CompanyArray = New Array();
	CompanyArray.Add(Organization);
	 
	CalculationPeriod = MonthEndTransactionsServer.CalculationStart(Catalogs.MonthEndClosingOperations.RDExpenseRecognition,
		EndOfMonth(Date),,CompanyArray);
	If CalculationPeriod > Date Then
		InformationRegisters.JobsForMonthEndClosing.CreateRegisterEntry(
			BegOfMonth(Date), Ref, Organization, Catalogs.MonthEndClosingOperations.RDExpenseRecognition);
	EndIf;
	
EndProcedure

#EndRegion

#EndIf