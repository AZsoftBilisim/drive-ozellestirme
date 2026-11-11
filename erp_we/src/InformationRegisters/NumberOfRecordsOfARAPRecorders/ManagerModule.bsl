#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Filling in the register of information "The number of records of the registrars of settlements" according to the movements 
// of the official document of the registrar.
// 
// Parameters:
//  DocumentRecorder - DocumentRef - Recorder
//  RegisterName - String - Name of the calculation register
//  DataImport - Boolean - True if sets of calculation register entries are loaded during data exchange
Procedure ReflectNumberOfRecordsOfPaymentRegistrars(DocumentRecorder, RegisterName, DataImport = False) Export

	If Not TypeOf(DocumentRecorder) = Type("DocumentRef.ARAPAccountingRecorder") Then
		Return;
	EndIf;

	Query = New Query;
	Query.Text = "
	|SELECT
	|	CalculationRegister.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	CalculationRegister.ARAPObject AS ARAPObject,
	|	CalculationRegister.Currency AS Currency,
	|	BEGINOFPERIOD(CalculationRegister.Period, DAY) AS RecordPeriod,
	|	CalculationRegister.Recorder AS Document,
	|	SUM(1) AS RecordsCount
	|FROM
	|	&TableName AS CalculationRegister
	|WHERE
	|	CalculationRegister.Recorder = &Recorder
	|GROUP BY
	|	CalculationRegister.AccountingDimensionByPartners,
	|	CalculationRegister.ARAPObject,
	|	CalculationRegister.Currency,
	|	CalculationRegister.Recorder,
	|	BEGINOFPERIOD(CalculationRegister.Period, DAY)";

	Query.SetParameter("Recorder", DocumentRecorder);

	Query.Text = StrReplace(Query.Text, "&TableName", "AccumulationRegister." + RegisterName);

	Selection = Query.Execute().Select();
	
	RecordSet = InformationRegisters.NumberOfRecordsOfARAPRecorders.CreateRecordSet();
	RecordSet.DataExchange.Load = DataImport;
	RecordSet.Filter.Document.Set(DocumentRecorder);
	RecordSet.Filter.TableName.Set(RegisterName);
	
	While Selection.Next() Do
		Record = RecordSet.Add();
		FillPropertyValues(Record, Selection);
		Record.TableName = RegisterName;
	EndDo;

	RecordSet.Write();

EndProcedure

#EndRegion

#EndIf