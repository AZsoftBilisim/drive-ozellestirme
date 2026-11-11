
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then
	
		Return;
	
	EndIf;

	Result = FormAttributeToValue("HistoryOfClassification");

	Query = New Query(
		"SELECT
		|	ClassificationPeriods.Period AS Period,
		|	CASE
		|		WHEN XYZProfit_.Class IS NULL 
		|			THEN VALUE(Enum.PhasesOfRelationshipsWithCustomers.PotentialCustomer)
		|		WHEN XYZProfit_.Class = VALUE(Enum.XYZClassification.ZClass)
		|			THEN VALUE(Enum.PhasesOfRelationshipsWithCustomers.OneTimeCustomer)
		|		WHEN XYZProfit_.Class = VALUE(Enum.XYZClassification.NotClassified)
		|			THEN VALUE(Enum.PhasesOfRelationshipsWithCustomers.LostCustomer)
		|		ELSE VALUE(Enum.PhasesOfRelationshipsWithCustomers.LoyalCustomer)
		|	END AS ProfitStage,
		|	ABCProfit_.Class AS ABCProfit_,
		|	XYZProfit_.Class AS XYZProfit_,
		|	CASE
		|		WHEN XYZRevenue.Class IS NULL 
		|			THEN VALUE(Enum.PhasesOfRelationshipsWithCustomers.PotentialCustomer)
		|		WHEN XYZRevenue.Class = VALUE(Enum.XYZClassification.ZClass)
		|			THEN VALUE(Enum.PhasesOfRelationshipsWithCustomers.OneTimeCustomer)
		|		WHEN XYZRevenue.Class = VALUE(Enum.XYZClassification.NotClassified)
		|			THEN VALUE(Enum.PhasesOfRelationshipsWithCustomers.LostCustomer)
		|		ELSE VALUE(Enum.PhasesOfRelationshipsWithCustomers.LoyalCustomer)
		|	END AS RevenueStage,
		|	ABCRevenue.Class AS ABCRevenue,
		|	XYZRevenue.Class AS XYZRevenue,
		|	CASE
		|		WHEN XYZCount.Class IS NULL 
		|			THEN VALUE(Enum.PhasesOfRelationshipsWithCustomers.PotentialCustomer)
		|		WHEN XYZCount.Class = VALUE(Enum.XYZClassification.ZClass)
		|			THEN VALUE(Enum.PhasesOfRelationshipsWithCustomers.OneTimeCustomer)
		|		WHEN XYZCount.Class = VALUE(Enum.XYZClassification.NotClassified)
		|			THEN VALUE(Enum.PhasesOfRelationshipsWithCustomers.LostCustomer)
		|		ELSE VALUE(Enum.PhasesOfRelationshipsWithCustomers.LoyalCustomer)
		|	END AS Stage_Count,
		|	ABCCount.Class AS ABCCount,
		|	XYZCount.Class AS XYZCount
		|FROM
		|	(SELECT
		|		ABCXYZCustomerClassification.Period AS Period
		|	FROM
		|		InformationRegister.ABCXYZCustomerClassification AS ABCXYZCustomerClassification
		|	WHERE
		|		ABCXYZCustomerClassification.Partner = &Partner
		|	
		|	GROUP BY
		|		ABCXYZCustomerClassification.Period) AS ClassificationPeriods
		|		LEFT JOIN InformationRegister.ABCXYZCustomerClassification AS ABCProfit_
		|		ON ClassificationPeriods.Period = ABCProfit_.Period
		|			AND (ABCProfit_.Partner = &Partner)
		|			AND (ABCProfit_.ClassificationType = VALUE(Enum.TypesOfClassification.ABC))
		|			AND (ABCProfit_.ClassificationParameterType = VALUE(Enum.TypesOfClassificationParameters.GrossProfit))
		|		LEFT JOIN InformationRegister.ABCXYZCustomerClassification AS ABCRevenue
		|		ON ClassificationPeriods.Period = ABCRevenue.Period
		|			AND (ABCRevenue.Partner = &Partner)
		|			AND (ABCRevenue.ClassificationType = VALUE(Enum.TypesOfClassification.ABC))
		|			AND (ABCRevenue.ClassificationParameterType = VALUE(Enum.TypesOfClassificationParameters.Revenue))
		|		LEFT JOIN InformationRegister.ABCXYZCustomerClassification AS ABCCount
		|		ON ClassificationPeriods.Period = ABCCount.Period
		|			AND (ABCCount.Partner = &Partner)
		|			AND (ABCCount.ClassificationType = VALUE(Enum.TypesOfClassification.ABC))
		|			AND (ABCCount.ClassificationParameterType = VALUE(Enum.TypesOfClassificationParameters.Count))
		|		LEFT JOIN InformationRegister.ABCXYZCustomerClassification AS XYZProfit_
		|		ON ClassificationPeriods.Period = XYZProfit_.Period
		|			AND (XYZProfit_.Partner = &Partner)
		|			AND (XYZProfit_.ClassificationType = VALUE(Enum.TypesOfClassification.XYZ))
		|			AND (XYZProfit_.ClassificationParameterType = VALUE(Enum.TypesOfClassificationParameters.GrossProfit))
		|		LEFT JOIN InformationRegister.ABCXYZCustomerClassification AS XYZRevenue
		|		ON ClassificationPeriods.Period = XYZRevenue.Period
		|			AND (XYZRevenue.Partner = &Partner)
		|			AND (XYZRevenue.ClassificationType = VALUE(Enum.TypesOfClassification.XYZ))
		|			AND (XYZRevenue.ClassificationParameterType = VALUE(Enum.TypesOfClassificationParameters.Revenue))
		|		LEFT JOIN InformationRegister.ABCXYZCustomerClassification AS XYZCount
		|		ON ClassificationPeriods.Period = XYZCount.Period
		|			AND (XYZCount.Partner = &Partner)
		|			AND (XYZCount.ClassificationType = VALUE(Enum.TypesOfClassification.XYZ))
		|			AND (XYZCount.ClassificationParameterType = VALUE(Enum.TypesOfClassificationParameters.Count))
		|
		|ORDER BY
		|	Period");
	Query.SetParameter("Partner", Parameters.Partner);
	Selection = Query.Execute();
	FieldsCount = Selection.Columns.Count() - 1;

	If Not Selection.IsEmpty() Then

		// fill in the classification history
		LastCut = Undefined; // Array, Undefined
		Selection = Selection.Select();
		While Selection.Next() Do

			// create a slice for the classification date
			CrossSection = New Array;
			For NumberOfFields = 0 To FieldsCount Do
				CrossSection.Add(Selection.Get(NumberOfFields));
			EndDo;

			// add a row when the current classification results change
			If LastCut = Undefined Then
				InsertRow(CrossSection, Result);
			Else
				SliceHasChanged = False;
				For NumberOfFields = 1 To FieldsCount Do
					CurrentValue = CrossSection.Get(NumberOfFields);
					PastValue = LastCut.Get(NumberOfFields);
					If CurrentValue <> PastValue Then
						If PastValue = Enums.PhasesOfRelationshipsWithCustomers.LostCustomer
						 Or PastValue = Enums.ABCClassification.NotClassified
						 Or PastValue = Enums.XYZClassification.NotClassified Then
							CurrentValue = PastValue;
						Else
							LastCut = CrossSection;
							InsertRow(CrossSection, Result);
							Break;
						EndIf;
					EndIf;
				EndDo;
			EndIf; //add a row when the current classification results change
		EndDo; //fill in the classification history

		// add a client registration line
		String = Result.Add();
		String.ChangeDate    = Parameters.Partner.RegistrationDate;
		String.Revenue          = NStr("vi = 'Khách hàng tiềm năng';
										|ru = 'Потенциальный клиент';
										|en = 'Potential customer'; fa = 'مشتری بالقوه';
										|it = 'Cliente potenziale';
										|pl = 'Potencjalny klient';
										|tr = 'Potansiyel müşteri'");
		String.GrossProfit   = String.Revenue;
		String.NumberOfSales = String.Revenue;

	EndIf;

	// hide unused columns
	Items.HistoryOfClassificationRevenue.Visible = 
		GetFunctionalOption("UseABCXYZClassificationOfPartnersByRevenue");
	Items.HistoryOfClassificationGrossProfit.Visible =
		GetFunctionalOption("UseABCXYZClassificationOfPartnersByGrossProfit");
	Items.HistoryOfClassificationNumberOfSales.Visible =
		GetFunctionalOption("UseABCXYZClassificationOfPartnersByNumberOfSales");

	ValueToFormAttribute(Result, "HistoryOfClassification");

EndProcedure

#EndRegion

#Region Private

#Region Other

&AtServer
Procedure InsertRow(CrossSection, Result)

	String = Result.Insert(0);
	String.ChangeDate = CrossSection.Get(0);
	String.GrossProfit   = ClassPresentation(CrossSection.Get(1), CrossSection.Get(2), CrossSection.Get(3));
	String.Revenue          = ClassPresentation(CrossSection.Get(4), CrossSection.Get(5), CrossSection.Get(6));
	String.NumberOfSales = ClassPresentation(CrossSection.Get(7), CrossSection.Get(8), CrossSection.Get(9));

EndProcedure

&AtServer
Function ClassPresentation(Phase, ABCClass, XYZClass)

	Result = String(Phase);
	ABCPresentation = "";
	PresentationOfXYZ = "";

	If ABCClass = Enums.ABCClassification.AClass Then

		ABCPresentation = "A";

	ElsIf ABCClass = Enums.ABCClassification.BClass Then

		ABCPresentation = "B";

	ElsIf ABCClass = Enums.ABCClassification.CClass Then

		ABCPresentation = "C";

	EndIf;

	If XYZClass = Enums.XYZClassification.XClass Then

		PresentationOfXYZ = "X";

	ElsIf XYZClass = Enums.XYZClassification.YClass Then

		PresentationOfXYZ = "Y";

	ElsIf XYZClass = Enums.XYZClassification.ZClass Then

		PresentationOfXYZ = "Z";

	EndIf;

	If ABCPresentation <> "" Or PresentationOfXYZ <> "" Then
		Result = Result + ", " + ABCPresentation + PresentationOfXYZ;
	EndIf;

	Return Result;

EndFunction

#EndRegion

#EndRegion
