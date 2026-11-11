#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region EventHandlers

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	If TypeOf(FillingData) = Type("Structure") 
		And FillingData.Property("VATTaxationType") Then 
		NewRow = VATTaxationTypes.Add();
		NewRow.VATTaxationType = FillingData.VATTaxationType;
	EndIf;
	
	If Not GetFunctionalOption("UseMultiCountryAccounting") Then
		Country = SettingsValueClientServerCached.MainCountry();
	EndIf;
	
EndProcedure

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	DataLock = New DataLock();
	DataLockItem = DataLock.Add("InformationRegister.BasicVATRates"); //DataLockItem
	DataLockItem.Mode = DataLockMode.Exclusive;
	DataLock.Lock();
	
	DataLock = New DataLock();
	DataLockItem = DataLock.Add("Catalog.VATRates"); //DataLockItem
	DataLockItem.Mode = DataLockMode.Shared;
	DataLock.Lock();
	
	// We will clear the records for this rate
	Query = New Query;
	Query.Text =
	"SELECT
	|	BasicVATRates.Country AS Country
	|INTO Countries
	|FROM
	|	InformationRegister.BasicVATRates AS BasicVATRates
	|WHERE
	|	BasicVATRates.VATRate = &Ref
	|
	|UNION
	|
	|SELECT
	|	&Country
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	VATRates.BeginOfPeriod AS Period,
	|	VATRates.Country AS Country,
	|	VATRates.Ref AS VATRate
	|FROM
	|	Catalog.VATRates AS VATRates
	|WHERE
	|	VATRates.Country IN
	|			(SELECT DISTINCT
	|				T.Country
	|			FROM
	|				Countries AS T)
	|	AND VATRates.Main
	|TOTALS BY
	|	Country";
	
	Query.SetParameter("Country", Country);
	Query.SetParameter("Ref", Ref);
	
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	SampleCountry = QueryResult.Select(QueryResultIteration.ByGroups);
	
	While SampleCountry.Next() Do
		
		RecordSet = InformationRegisters.BasicVATRates.CreateRecordSet();
		RecordSet.Filter.Country.Set(SampleCountry.Country);
		
		SelectionDetailRecords = SampleCountry.Select();
		While SelectionDetailRecords.Next() Do
			NewRecord = RecordSet.Add();
			FillPropertyValues(NewRecord, SelectionDetailRecords);
			If Not ValueIsFilled(NewRecord.Period) Then
				NewRecord.Period = Date("19800101");
			EndIf;
		EndDo;
		
		RecordSet.Write();
		
	EndDo;
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If ValueIsFilled(BeginOfPeriod) And ValueIsFilled(EndOfPeriod) Then
		If BeginOfPeriod >= EndOfPeriod Then
			ErrorText = NStr("vi = 'Ngày cuối kỳ hiệu lực của thuế suất GTGT phải lớn hơn ngày đầu kỳ.';
							|ru = 'Дата окончания периода действия ставки НДС должна быть больше даты начала.';
							|en = 'The validity period end date of the VAT rate must be greater than the start date.'; fa = 'The validity period end date of the VAT rate must be greater than the start date.';
							|it = 'La data di fine del periodo di validità dell''aliquota IVA deve essere successiva alla data di inizio.';
							|pl = 'Data zakończenia okresu ważności stawki VAT powinna być większa niż data początku.';
							|tr = 'KDV oranı döneminin bitiş tarihi, başlangıç ​​tarihinden büyük olmalıdır.'");
			Common.MessageToUser(ErrorText, Ref, "EndOfPeriod",, Cancel);
		EndIf;
	EndIf;
	
	NotCheckedAttributeArray = New Array;
	If Ref = Catalogs.VATRates.EXCLUDINGVAT Then
		NotCheckedAttributeArray.Add(Metadata().Attributes.Country.Name);
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

Procedure OnReadPresentationsAtServer() Export
	// StandardSubsystems.Core
	NationalLanguageSupportServer.OnReadPresentationsAtServer(ThisObject);
	// End StandardSubsystems.Core
EndProcedure

#EndRegion

#EndIf
