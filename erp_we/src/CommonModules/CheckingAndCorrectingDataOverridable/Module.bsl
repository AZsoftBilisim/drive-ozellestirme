#Region Public

// It is called when creating a list of check/correction treatments available to the user. It allows you to add
// your own treatments to the generated list.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//   Handlers - Map - matching, where:
//     * Key - UUID - verification ID.
//     * Value - String - the name of the validation module that contains the following export procedures:
//         Checking and correcting the data to fill in the entries, procedure parameters:
//              * InformationRecords - Structure - structure with keys:
//                   ** Description - String - name of the check.
//                   ** LongDesc - String - description of the check, optional.
//                   ** SeparatedData - Boolean - what data will be checked, depending on this value,
//                           different checks will be shown in different modes.
//                   ** Settings - Structure - settings that the user can edit. It makes sense to fill
//                         in if the settings form is specified. These settings will be saved between uses.
//                   ** SettingsForm - String - full name of the settings form, optional.
//                         The following parameters are passed to the settings form:
//                           * Settings - String - the address in the temporary storage where the settings are stored. 
//                           * TemporaryData - String - the address in the temporary storage where temporary data is stored
//                                 (not saved between uses).
//                           * Correct - Boolean - if True, then data correction is required.
//                         In the settings form, after editing, all settings should be placed in temporary storage with
//                         new addresses and the structure with keys should be returned:
//                           * Settings - String - the address in the temporary storage where the settings are stored. 
//                           * TemporaryData - String - the address in the temporary storage where temporary data is stored.
//         Checking and correcting data_Check settings, procedure parameters:
//              * Settings - Structure - settings obtained from the fill in the Results procedure.
//              * TemporaryData - Structure - temporary settings obtained from the settings form.
//              * Correct - Boolean - True if data correction is required.
//              * Cancel - Boolean - if you set the value to True, then the settings contain errors.
//         Checking and correcting data_Check the data, procedure parameters:
//              * Settings - Structure - settings obtained from the fill in the Results procedure.
//              * TemporaryData - Structure - temporary settings obtained from the settings form.
//              * Correct - Boolean - True if data correction is required.
//              * Result - Structure - structure whose values need to be filled in, keys:
//                 ** IssuesFound - Boolean - False by default.
//                 ** ResultPresentation - String - a brief presentation of the result, 
//                    if problems are found = True, then it is mandatory to fill in.
//                 ** SpreadsheetDocument - SpreadsheetDocument - detailed view, optional.
//
// Example:
//   Handlers.Insert(New unique identifier ("2b1043e2-9e00-4518-ac0d-1a2befdcce1x"), 
//   					  " Processing.Checking the measuringregistrachbuchgalteria");
//
Procedure OnFillChecks(Handlers) Export
EndProcedure

#EndRegion
