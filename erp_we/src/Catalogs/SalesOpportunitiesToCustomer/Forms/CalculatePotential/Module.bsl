
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	CurrencyOfManAccounting = String(Parameters.CurrencyOfManAccounting);
	
	// set the heading taking into account the currency of management accounting
	Items.Potential.Title = NStr("vi = 'Tiềm năng (%Currency%)';
								|ru = 'Потенциал (%Currency%)';
								|en = 'Potential (%Currency%)'; fa = 'Potential (%Currency%)';
								|it = 'Potenziale (%Currency%)';
								|pl = 'Potencjał (%Currency%)';
								|tr = 'Potansiyel (%Currency%)'");
	Items.Potential.Title = StrReplace(Items.Potential.Title, "%Currency%",Constants.ManagementAccountingCurrency.Get());

	// upload a list of documents
	Query = New Query("
		|SELECT
		|	SUM(SalesOpportunitiesToCustomerPrimaryDemand.Sum) AS DocumentAmount,
		|	SalesOpportunitiesToCustomerPrimaryDemand.Ref AS Ref
		|INTO DocumentData
		|	FROM
		|	Catalog.SalesOpportunitiesToCustomer.PrimaryDemand AS SalesOpportunitiesToCustomerPrimaryDemand
		|GROUP BY
		|	SalesOpportunitiesToCustomerPrimaryDemand.Ref
		|;
		|////////////////////////////////////////////////////////////////////////////
		|
		|SELECT ALLOWED
		|	&PrimaryDemand AS Document,
		|	1 AS DORDER,
		|	CASE
		|		WHEN SalesOpportunitiesToCustomer.PrimaryDemandCurrency = ManSExchangeRates.Currency
		|			THEN DocumentData.DocumentAmount
		|		ELSE DocumentData.DocumentAmount * ISNULL(DocumentCurrencyRates.CourseNumerator, 1) * ISNULL(ManSExchangeRates.CourseDenominator, 1) / (ISNULL(ManSExchangeRates.CourseNumerator, 1) * ISNULL(DocumentCurrencyRates.CourseDenominator, 1))
		|	END AS Potential,
		|	"""" AS Status
		|FROM
		|	Catalog.SalesOpportunitiesToCustomer AS SalesOpportunitiesToCustomer
		|		INNER JOIN DocumentData AS DocumentData
		|		ON SalesOpportunitiesToCustomer.Ref = DocumentData.Ref
		|		INNER JOIN InformationRegister.RelativeExchangeRates.SliceLast(, BaseCurrency = &BaseCurrency) AS DocumentCurrencyRates
		|		ON SalesOpportunitiesToCustomer.PrimaryDemandCurrency = DocumentCurrencyRates.Currency,
		|	InformationRegister.RelativeExchangeRates.SliceLast(
		|			,
		|			Currency IN
		|				(SELECT
		|					Constants.ManagementAccountingCurrency
		|				FROM
		|					Constants AS Constants)
		|			AND BaseCurrency = &BaseCurrency) AS ManSExchangeRates
		|WHERE
		|	SalesOpportunitiesToCustomer.Ref = &FilterDocument_
		|	AND DocumentData.DocumentAmount > 0
		|
		|UNION ALL
		|
		|SELECT
		|	TermsOfSale.Ref,
		|	2,
		|	CASE
		|		WHEN TermsOfSale.Currency = ManSExchangeRates.Currency
		|			THEN TermsOfSale.DocumentAmount
		|		ELSE TermsOfSale.DocumentAmount * ISNULL(DocumentCurrencyRates.CourseNumerator, 1) * ISNULL(ManSExchangeRates.CourseDenominator, 1) / (ISNULL(ManSExchangeRates.CourseNumerator, 1) * ISNULL(DocumentCurrencyRates.CourseDenominator, 1))
		|	END,
		|	PRESENTATION(TermsOfSale.Status)
		|FROM
		|	InformationRegister.RelativeExchangeRates.SliceLast(
		|			,
		|			Currency IN
		|				(SELECT
		|					Constants.ManagementAccountingCurrency
		|				FROM
		|					Constants AS Constants)
		|			AND BaseCurrency = &BaseCurrency) AS ManSExchangeRates,
		|	Catalog.SalesOpportunitiesToCustomer AS SalesOpportunitiesToCustomer
		|		LEFT JOIN Catalog.TermsOfSale AS TermsOfSale
		|			LEFT JOIN InformationRegister.RelativeExchangeRates.SliceLast(, BaseCurrency = &BaseCurrency) AS DocumentCurrencyRates
		|			ON TermsOfSale.Currency = DocumentCurrencyRates.Currency
		|		ON SalesOpportunitiesToCustomer.CustomerTermsOfSales = TermsOfSale.Ref
		|WHERE
		|	TermsOfSale.DeletionMark = FALSE
		|	AND SalesOpportunitiesToCustomer.Ref = &FilterDocument_
		|	AND TermsOfSale.DocumentAmount > 0
		|
		|UNION ALL
		|
		|SELECT
		|	SalesOrder.Ref,
		|	3.5,
		|	CASE
		|		WHEN SalesOrder.Currency = ManSExchangeRates.Currency
		|			THEN SalesOrder.DocumentAmount
		|		ELSE SalesOrder.DocumentAmount * ISNULL(DocumentCurrencyRates.CourseNumerator, 1) * ISNULL(ManSExchangeRates.CourseDenominator, 1) / (ISNULL(ManSExchangeRates.CourseNumerator, 1) * ISNULL(DocumentCurrencyRates.CourseDenominator, 1))
		|	END,
		|	PRESENTATION(SalesOrder.Status)
		|FROM
		|	Document.SalesOrder AS SalesOrder
		|		LEFT JOIN InformationRegister.RelativeExchangeRates.SliceLast(, BaseCurrency = &BaseCurrency) AS DocumentCurrencyRates
		|		ON SalesOrder.Currency = DocumentCurrencyRates.Currency,
		|	InformationRegister.RelativeExchangeRates.SliceLast(
		|			,
		|			Currency IN
		|				(SELECT
		|					Constants.ManagementAccountingCurrency
		|				FROM
		|					Constants AS Constants)
		|			AND BaseCurrency = &BaseCurrency) AS ManSExchangeRates
		|WHERE
		|	SalesOrder.DeletionMark = FALSE
		|	AND SalesOrder.SalesOpportunity = &FilterDocument_
		|	AND SalesOrder.DocumentAmount > 0
		|
		|ORDER BY
		|	DORDER");
	
	CRMLocalization.AddRequestToCalculateTransactionPotential(Query.Text);
	
	Query.SetParameter("FilterDocument_", Parameters.Key);
	Query.SetParameter("PrimaryDemand", NStr("vi = 'Nhu cầu ban đầu';
											|ru = 'Первичный спрос';
											|en = 'Primary demand'; fa = 'تقاضای اولیه';
											|it = 'Domanda primaria';
											|pl = 'Pierwotny popyt';
											|tr = 'Birincil talep'"));
	Query.SetParameter("BaseCurrency", SettingsValueCached.DefaultBaseCurrency());
	DocumentsList = Query.Execute().Unload();
	DocumentsList.Columns.Add("Selected");
	ValueToFormAttribute(DocumentsList, "List");
	
	GenerateStringSumOfPotential(ThisObject);
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure SelectedOnChange(Item)

	PotentialAmount = 0;

	For Each Item In List Do
		If Item.Selected Then
			PotentialAmount = PotentialAmount + Item.Potential;
		EndIf;
	EndDo;
	
	GenerateStringSumOfPotential(ThisObject)

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SelectAll_2(Command)

	PotentialAmount = 0;

	For Each Item In List Do
		Item.Selected = True;
		PotentialAmount = PotentialAmount + Item.Potential;
	EndDo;
	
	GenerateStringSumOfPotential(ThisObject)

EndProcedure

&AtClient
Procedure ClearSelection(Command)

	PotentialAmount = 0;

	For Each Item In List Do
		Item.Selected = False;
	EndDo;

EndProcedure

&AtClient
Procedure SetThePotential(Command)

	Close(PotentialAmount);

EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

&AtClientAtServerNoContext
Procedure GenerateStringSumOfPotential(Form)

	Form.LinePotentialAmount = String(Form.PotentialAmount) + " " + Form.CurrencyOfManAccounting + ".";

EndProcedure


#EndRegion
