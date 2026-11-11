#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)

	If DataExchange.Load Or Not DocumentsPosting.CalculateChanges_(AdditionalProperties) Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);

	LockForUpdate = True;

	// The Cur State of the set is placed in the temporary table "
	// Product formalizeapplication before recording" in order to get a change in the new set relative to the Cur when recording.
	Query = New Query;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	Query.SetParameter("IsNew",    AdditionalProperties.DocumentProperties.IsNew);
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	Query.Text =
	"SELECT
	|	Table.DocumentInflow AS DocumentInflow,
	|	Table.Products AS Products,
	|	Table.Characteristic AS Characteristic,
	|	Table.Series AS Series,
	|	Table.Warehouse AS Warehouse,
	|	CASE
	|		WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN Table.ToRegister
	|		ELSE -Table.ToRegister
	|	END AS ToRegisterBeforeWrite,
	|	CASE
	|		WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN Table.TaxInvoicedPrice
	|		ELSE -Table.TaxInvoicedPrice
	|	END AS TaxInvoicedPriceBeforeWrite
	|INTO GoodsForRegistrationOfApplicationForImportFromEEUCountriesBeforeWrite
	|FROM
	|	AccumulationRegister.GoodsForRegistrationOfApplicationForImportFromEEUCountries AS Table
	|WHERE
	|	Table.Recorder = &Recorder
	|	AND NOT &IsNew";
	Query.Execute();

EndProcedure

Procedure OnWrite(Cancel, Replacing)

	If DataExchange.Load Or Not DocumentsPosting.CalculateChanges_(AdditionalProperties) Then
		Return;
	EndIf;
	
	// The change of the new set relative to the current one is calculated taking into account the accumulated changes
	// and placed in a temporary table.
	Query = New Query;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	Query.Text =
	"SELECT
	|	ChangesTable.DocumentInflow AS DocumentInflow,
	|	ChangesTable.Products AS Products,
	|	ChangesTable.Characteristic AS Characteristic,
	|	ChangesTable.Series AS Series,
	|	ChangesTable.Warehouse AS Warehouse,
	|	SUM(ChangesTable.ToRegisterUpdate) AS ToRegisterUpdate,
	|	SUM(ChangesTable.TaxInvoicedPriceUpdate) AS TaxInvoicedPriceUpdate
	|INTO GoodsForRegistrationOfApplicationForImportFromEEUCountriesUpdate
	|FROM
	|	(SELECT
	|		Table.DocumentInflow AS DocumentInflow,
	|		Table.Products AS Products,
	|		Table.Characteristic AS Characteristic,
	|		Table.Series AS Series,
	|		Table.Warehouse AS Warehouse,
	|		Table.ToRegisterBeforeWrite AS ToRegisterUpdate,
	|		Table.TaxInvoicedPriceBeforeWrite AS TaxInvoicedPriceUpdate
	|	FROM
	|		GoodsForRegistrationOfApplicationForImportFromEEUCountriesBeforeWrite AS Table
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Table.DocumentInflow,
	|		Table.Products,
	|		Table.Characteristic,
	|		Table.Series,
	|		Table.Warehouse,
	|		CASE
	|			WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -Table.ToRegister
	|			ELSE Table.ToRegister
	|		END,
	|		CASE
	|			WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -Table.TaxInvoicedPrice
	|			ELSE Table.TaxInvoicedPrice
	|		END
	|	FROM
	|		AccumulationRegister.GoodsForRegistrationOfApplicationForImportFromEEUCountries AS Table
	|	WHERE
	|		Table.Recorder = &Recorder) AS ChangesTable
	|
	|GROUP BY
	|	ChangesTable.DocumentInflow,
	|	ChangesTable.Products,
	|	ChangesTable.Characteristic,
	|	ChangesTable.Series,
	|	ChangesTable.Warehouse
	|
	|HAVING
	// According to the co-registration, an increase in arrival and a decrease in expenditure will lead to an incorrect State of the register.
	|	(SUM(ChangesTable.ToRegisterUpdate) <> 0 
	// According to the texture value, any change will lead to an incorrect State of the register.
	|		OR SUM(ChangesTable.TaxInvoicedPriceUpdate) <> 0) 
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|DROP GoodsForRegistrationOfApplicationForImportFromEEUCountriesBeforeWrite";
	
	Selection = Query.ExecuteBatch()[0].Select();
	DocumentsPosting.RegisterControlTable(AdditionalProperties,
		"GoodsForRegistrationOfApplicationForImportFromEEUCountriesUpdate", Selection.Next() And Selection.Count > 0);
	
EndProcedure

#EndRegion

#EndIf
