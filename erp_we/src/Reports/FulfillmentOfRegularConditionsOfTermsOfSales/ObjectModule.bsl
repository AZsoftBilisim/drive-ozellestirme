#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Settings for the General report form in the report Options subsystem.
//
// Parameters:
//   Form - ClientApplicationForm - report form.
//   VariantKey - String - The name of the predefined report variant or the unique ID of the custom one.
//   Settings - See ReportsClientServer.GetDefaultReportSettings
//
Procedure DefineFormSettings(Form, VariantKey, Settings) Export
	Settings.Events.OnCreateAtServer = True;
EndProcedure

// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
//   ThisForm - ClientApplicationForm - The Form of the report. Contains including:
//   	* Parameters - Structure - The parameter structure contains, among other things:
//   		** CommandDetails - Structure:
//   			*** AdditionalParameters - Structure:
//   				**** CommandName - String
//   Cancel - Boolean - passed from the handler parameters "as is".
//   StandardProcessing - Boolean - passed from the handler parameters "as is".
//
// See also:
//   "Formaclientapplications.Joining the server" in the syntax assistant.
//
Procedure OnCreateAtServer(ThisForm, Cancel, StandardProcessing) Export
	
	FormSettingsComposer = ThisForm.Report.SettingsComposer;
	Parameters = ThisForm.Parameters;
	
	If Parameters.Property("CommandParameter")
			And Parameters.Property("CommandDetails")
			And Parameters.CommandDetails.Property("AdditionalParameters") Then 
		
		If Parameters.CommandDetails.AdditionalParameters.CommandName = "FulfillmentOfRegularConditionsOfTermsOfSales" Then
			ThisForm.ParametersForm.Filter.Insert("Terms", Parameters.CommandParameter);
		ElsIf Parameters.CommandDetails.AdditionalParameters.CommandName = "FulfillmentOfTermsOfAgreementsWithClientsOnPartner" Then
			ThisForm.ParametersForm.Filter.Insert("Partner", Parameters.CommandParameter);
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrencyParameter = DataCompositionClientServer.GetParameter(SettingsComposer, "ReportCurrency");
	
	If CurrencyParameter <> Undefined And Not CurrencyParameter.Use Then
		CurrencyParameter.Use = True;
	EndIf;
	
	ReportDateParameter = DataCompositionClientServer.GetParameter(SettingsComposer, "ReportDate");
	
	If ReportDateParameter <> Undefined And Not ReportDateParameter.Use Then
		ReportDateParameter.Use = True;
	EndIf;
	
	AgreementParameter = DataCompositionClientServer.GetParameter(SettingsComposer.FixedSettings, "Terms");
	PartnerParameter    = DataCompositionClientServer.GetParameter(SettingsComposer.FixedSettings, "Partner");

	If AgreementParameter <> Undefined And PartnerParameter <> Undefined And CurrencyParameter <> Undefined Then
		
		Query = New Query("
			|////////////////////////////////////////////////////////////////////////////////
			|// EXCHANGE RATES /////////////////////////////////////////////////////////////////
			|
			|SELECT ALLOWED
			|	CurrencyRatesCut.Currency    AS Currency,
			|	CurrencyRatesCut.CourseNumerator AS CourseNumerator,
			|	CurrencyRatesCut.CourseDenominator AS CourseDenominator
			|INTO CurrencyRatesCut
			|FROM
			|	InformationRegister.RelativeExchangeRates.SliceLast({&EndDate}, BaseCurrency = &BaseCurrency) AS CurrencyRatesCut
			|INDEX BY
			|	Currency
			|;
			|////////////////////////////////////////////////////////////////////////////////
			|// result ///////////////////////////////////////////////////////////////////
			|
			|SELECT ALLOWED
			|	CustomerTermsOfSales.Date                  AS Date,
			|	CustomerTermsOfSales.Description          AS Description,
			|	CustomerTermsOfSales.Ref                AS Terms,
			|	CustomerTermsOfSales.Period                AS Periodicity,
			|	CustomerTermsOfSales.NumberOfPeriods    AS NumberOfPeriods,
			|	CustomerTermsOfSales.ValidityStartDate    AS ValidityStartDate,
			|	CustomerTermsOfSales.ValidityEndDate AS ValidityEndDate,
			|	CustomerTermsOfSales.Partner               AS Partner,
			|CASE
			|	WHEN
			|		&Currency = VALUE(Catalog.Currencies.EmptyRef)
			|		OR &Currency = UNDEFINED
			|		OR &Currency = CustomerTermsOfSales.Currency
			|	THEN
			|		CustomerTermsOfSales.DocumentAmount
			|	ELSE
			|		CAST(CustomerTermsOfSales.DocumentAmount *
			|			CASE
			|				WHEN ISNULL(CurrencyExchangeRateOfSliceReport.CourseDenominator, 0) > 0
			|					AND ISNULL(CurrencyExchangeRateOfSliceReport.CourseNumerator, 0) > 0
			|					AND ISNULL(CurrencyRatesCrossSectionDocumentCurrency.CourseDenominator, 0) > 0
			|					AND ISNULL(CurrencyRatesCrossSectionDocumentCurrency.CourseNumerator, 0) > 0
			|				THEN
			|					(CurrencyRatesCrossSectionDocumentCurrency.CourseNumerator * CurrencyExchangeRateOfSliceReport.CourseDenominator)
			|					/ (CurrencyExchangeRateOfSliceReport.CourseNumerator * CurrencyRatesCrossSectionDocumentCurrency.CourseDenominator)
			|				ELSE
			|					0
			|			END AS NUMBER(31,2))
			|END AS AgreementAmount,
			|CASE
			|	WHEN
			|		&Currency = VALUE(Catalog.Currencies.EmptyRef)
			|		OR &Currency = UNDEFINED
			|	THEN
			|		CustomerTermsOfSales.Currency
			|	ELSE
			|		&Currency
			|END AS Currency,
			|CASE
			|	WHEN
			|		CustomerTermsOfSales.Status = VALUE(Enum.StatusesOfTermsOfSales.Valid)
			|	THEN
			|		FALSE
			|	ELSE
			|		TRUE
			|END AS ThereAreErrorsStatus,
			|NOT CustomerTermsOfSales.Frequent AS ThereAreRegularErrors,
			|CustomerTermsOfSales.Standard_       AS ThereAreErrorsTypical
			|FROM
			|	Catalog.TermsOfSale AS CustomerTermsOfSales
			|
			|LEFT JOIN
			|	CurrencyRatesCut AS CurrencyRatesCrossSectionDocumentCurrency
			|ON
			|	CurrencyRatesCrossSectionDocumentCurrency.Currency = CustomerTermsOfSales.Currency
			|
			|LEFT JOIN
			|	CurrencyRatesCut AS CurrencyExchangeRateOfSliceReport
			|ON
			|	CurrencyExchangeRateOfSliceReport.Currency = &Currency
			|");
			
		If ValueIsFilled(PartnerParameter.Value) Then
			
			If TypeOf(PartnerParameter.Value) = Type("ValueList") Then
			
				Query.Text = Query.Text +
					"WHERE
					|	CustomerTermsOfSales.Partner IN (&Partner)
					|	AND CustomerTermsOfSales.Frequent
					|	AND NOT CustomerTermsOfSales.DeletionMark
					|	AND CustomerTermsOfSales.Status = VALUE(Enum.StatusesOfTermsOfSales.Valid)";
					
				Else
					
				Query.Text = Query.Text +
					"WHERE
					|	CustomerTermsOfSales.Partner = &Partner
					|	AND CustomerTermsOfSales.Frequent
					|	AND NOT CustomerTermsOfSales.DeletionMark
					|	AND CustomerTermsOfSales.Status = VALUE(Enum.StatusesOfTermsOfSales.Valid)";
					
				EndIf;
				
			Query.SetParameter("Partner", PartnerParameter.Value);
				
		ElsIf ValueIsFilled(AgreementParameter.Value) Then
				
			Query.Text = Query.Text +
				"WHERE
				|	CustomerTermsOfSales.Ref IN (&Terms)";
				
			Query.SetParameter("Terms", AgreementParameter.Value);
			
		Else
				
			Query.Text = Query.Text +
				"WHERE
				|	NOT CustomerTermsOfSales.Standard_
				|	AND CustomerTermsOfSales.Frequent
				|	AND NOT CustomerTermsOfSales.DeletionMark
				|	AND CustomerTermsOfSales.Status = VALUE(Enum.StatusesOfTermsOfSales.Valid)
				|";
				
		EndIf;
		
		Query.SetParameter("Currency", CurrencyParameter.Value);
		Query.SetParameter("BaseCurrency", SettingsValueCached.DefaultBaseCurrency());
		
		Selection = Query.Execute().Select();
		
		TableOfAgreements_ = New ValueTable();
		TableOfAgreements_.Columns.Add("Description");
		TableOfAgreements_.Columns.Add("Terms");
		TableOfAgreements_.Columns.Add("Periodicity");
		TableOfAgreements_.Columns.Add("AgreementAmount");
		TableOfAgreements_.Columns.Add("PeriodBeginning");
		TableOfAgreements_.Columns.Add("PeriodEnd");
		TableOfAgreements_.Columns.Add("Partner");
		TableOfAgreements_.Columns.Add("Currency");
		TableOfAgreements_.Columns.Add("ValidityStartDate");
		TableOfAgreements_.Columns.Add("ValidityEndDate");
		TableOfAgreements_.Columns.Add("Date");
		
		Cancel = False;
		
		While Selection.Next() Do
			
			If Selection.ThereAreErrorsStatus Then
				
				ErrorText = NStr("vi = 'Thỏa thuận với khách hàng ""%Terms%"" cần đặt ở trạng thái ""Thực hiện""';
								|ru = 'Соглашение с клиентом ""%Terms%"" должно быть в статусе ""Действует"".';
								|en = 'Customer agreement ""%Terms%"" should be in status ""Valid"".'; fa = 'Customer agreement ""%Terms%"" should be in status ""Valid"".';
								|it = 'L''accordo con il cliente ""%Terms%"" deve essere nello stato di ""Attivo"".';
								|pl = 'Umowa z klientem ""%Terms%"" musi mieć status ""Ważna"".';
								|tr = 'Satış koşulları ""%Terms%"" durumu ""Geçerli"" olmalıdır.'");
					ErrorText = StrReplace(ErrorText, "%Terms%", Selection.Terms);
					
				CommonClientServer.MessageToUser(
					ErrorText,
					,
					,
					,
					Cancel);
					
			EndIf;
			
			If Selection.ThereAreRegularErrors Then
				
				ErrorText = NStr("vi = 'Thỏa thuận với khách hàng ""%Terms%"" cần thường xuyên.';
								|ru = 'Соглашение с клиентом ""%Terms%"" должно быть регулярным.';
								|en = 'Customer agreement ""%Terms%"" should be regular.'; fa = 'Customer agreement ""%Terms%"" should be regular.';
								|it = 'L''accordo con il cliente ""%Terms%"" deve essere regolare.';
								|pl = 'Umowa z klientem ""%Terms%"" powinna być regularna.';
								|tr = 'Satış koşulları ""%Terms%"" düzenli olmalıdır.'");
					ErrorText = StrReplace(ErrorText, "%Terms%", Selection.Terms);
					
				CommonClientServer.MessageToUser(
					ErrorText,
					,
					,
					,
					Cancel);
				
			EndIf;
			
			If Selection.ThereAreErrorsTypical Then
				
				ErrorText = NStr("vi = 'Thỏa thuận với khách hàng %Terms% phải là thỏa thuận riêng.';
								|ru = 'Соглашение с клиентом %Terms% должно быть индивидуальным.';
								|en = 'Customer agreement %Terms% should be individual.'; fa = 'Customer agreement %Terms% should be individual.';
								|it = 'L''accordo con il cliente ""%Terms%"" deve essere individuale.';
								|pl = 'Umowa z klientem ""%Terms%"" powinna być indywidualna.';
								|tr = 'Satış koşulları ""%Terms%"" özelleştirilmiş olmalıdır.'");
					ErrorText = StrReplace(ErrorText, "%Terms%", Selection.Terms);
					
				CommonClientServer.MessageToUser(
					ErrorText,
					,
					,
					,
					Cancel);
					
			EndIf;
			
			If Not Cancel Then
			
				PreviousPeriod_ = Date(1,1,1);
				StartDateOfNearestPeriod = BegOfDay(TMCommonUseClientServer.CalculateStartDateOfNearestPeriod(Selection.ValidityStartDate, Selection.Periodicity));
				
				For CurrentPeriod = 0 To Selection.NumberOfPeriods-1 Do
					
					NewRow = TableOfAgreements_.Add();
					FillPropertyValues(NewRow, Selection);

					If CurrentPeriod = 0 Then
						NewRow.PeriodBeginning = BegOfDay(StartDateOfNearestPeriod);
					Else
						NewRow.PeriodBeginning = BegOfDay(TMCommonUseClientServer.CalculatePeriodEndDate(StartDateOfNearestPeriod, Selection.Periodicity, CurrentPeriod)+86400);
					EndIf;
					
					NewRow.PeriodEnd = TMCommonUseClientServer.CalculatePeriodEndDate(StartDateOfNearestPeriod, Selection.Periodicity, CurrentPeriod+1);
					
				EndDo;
				
			EndIf;
		
		EndDo;
		
		If TableOfAgreements_.Count() > 0 Then
				
			StartDateParameter    = DataCompositionClientServer.GetParameter(SettingsComposer, "StartDate");
			EndDateParameter = DataCompositionClientServer.GetParameter(SettingsComposer, "EndDate");
			
			TableOfDates = TableOfAgreements_.Copy(,"ValidityStartDate,ValidityEndDate");
			TableOfDates.Sort("ValidityStartDate Asc");
			
			If StartDateParameter <> Undefined Then
				StartDateParameter.Value = TableOfDates[0].ValidityStartDate;
				StartDateParameter.Use = True;
			EndIf;
			
			TableOfDates.Sort("ValidityEndDate Desc");
			
			If EndDateParameter <> Undefined Then
				EndDateParameter.Value = New Boundary(EndOfDay(TableOfDates[0].ValidityEndDate), BoundaryType.Including);
				EndDateParameter.Use = True;
			EndIf;
			
		EndIf;
			
		ExternalDataSets = New Structure();
		ExternalDataSets.Insert("Terms1", TableOfAgreements_);
		
		If Cancel Then
			Return;
		EndIf;
		
	EndIf;
	
	SegmentsServer.EnableSelectionByVSKDPartnerSegment(SettingsComposer);	
	
	DataCompositionSchema = GetTemplate("MainDataCompositionSchema");

	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate   = TemplateComposer.Execute(DataCompositionSchema, SettingsComposer.GetSettings(), DetailsData);
	
	DataCompositionProcessor = New DataCompositionProcessor;
	DataCompositionProcessor.Initialize(CompositionTemplate, ExternalDataSets, DetailsData, True);
	
	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	OutputProcessor.Output(DataCompositionProcessor);

EndProcedure

#EndRegion

#EndIf
