import fs from 'node:fs/promises';
import path from 'node:path';

const CSV_FILE = path.join(process.cwd(), 'data', 'texas.csv');

async function validateTexasCsv() {
  console.log('Validating Texas settlements CSV...');
  
  try {
    const content = await fs.readFile(CSV_FILE, 'utf8');
    const lines = content.split('\n');
    
    // Check if file is empty
    if (lines.length === 0) {
      throw new Error('CSV file is empty');
    }
    
    // Check headers
    const expectedHeaders = ['name', 'population', 'type', 'source_year'];
    const headers = lines[0].split(',');
    
    if (headers.length !== expectedHeaders.length) {
      throw new Error(`Expected ${expectedHeaders.length} headers, got ${headers.length}`);
    }
    
    for (let i = 0; i < expectedHeaders.length; i++) {
      if (headers[i] !== expectedHeaders[i]) {
        throw new Error(`Header mismatch at position ${i}: expected '${expectedHeaders[i]}', got '${headers[i]}'`);
      }
    }
    
    console.log('✓ Headers are correct');
    
    // Check data rows
    const dataLines = lines.slice(1).filter(line => line.trim().length > 0);
    let validRows = 0;
    let errors = [];
    
    const validTypes = new Set(['city', 'town', 'village', 'CDP', 'unincorporated']);
    const seenEntries = new Set();
    
    for (let i = 0; i < dataLines.length; i++) {
      const lineNum = i + 2; // Account for header + 0-based index
      const line = dataLines[i];
      const fields = line.split(',');
      
      // Check field count
      if (fields.length !== 4) {
        errors.push(`Line ${lineNum}: Expected 4 fields, got ${fields.length}`);
        continue;
      }
      
      const [name, population, type, sourceYear] = fields;
      
      // Check required name field
      if (!name || name.trim().length === 0) {
        errors.push(`Line ${lineNum}: Name is required`);
        continue;
      }
      
      // Check type is valid
      if (!validTypes.has(type)) {
        errors.push(`Line ${lineNum}: Invalid type '${type}'. Must be one of: ${Array.from(validTypes).join(', ')}`);
        continue;
      }
      
      // Check for duplicates (name + type combination)
      const key = `${name.toLowerCase()}_${type}`;
      if (seenEntries.has(key)) {
        errors.push(`Line ${lineNum}: Duplicate entry for '${name}' of type '${type}'`);
        continue;
      }
      seenEntries.add(key);
      
      // Check Census entries have required fields
      if (sourceYear === '2020' && (!population || population.trim().length === 0)) {
        errors.push(`Line ${lineNum}: Census entries (source_year=2020) must have population data`);
        continue;
      }
      
      // Check population is numeric when provided
      if (population && population.trim().length > 0) {
        const popNum = parseInt(population, 10);
        if (isNaN(popNum) || popNum < 0) {
          errors.push(`Line ${lineNum}: Population must be a non-negative integer, got '${population}'`);
          continue;
        }
      }
      
      validRows++;
    }
    
    // Check file ends with newline
    if (!content.endsWith('\n')) {
      errors.push('File does not end with a newline');
    }
    
    // Report results
    console.log(`✓ Processed ${dataLines.length} data rows`);
    console.log(`✓ ${validRows} valid entries`);
    
    if (errors.length > 0) {
      console.log(`\n❌ Found ${errors.length} validation errors:`);
      errors.forEach(error => console.log(`  - ${error}`));
      process.exit(1);
    } else {
      console.log('✅ All validations passed!');
      
      // Summary statistics
      const stats = {
        total: validRows,
        withPopulation: dataLines.filter(line => {
          const pop = line.split(',')[1];
          return pop && pop.trim().length > 0;
        }).length,
        byType: {}
      };
      
      validTypes.forEach(type => {
        stats.byType[type] = dataLines.filter(line => line.split(',')[2] === type).length;
      });
      
      console.log('\n📊 Summary:');
      console.log(`  Total entries: ${stats.total}`);
      console.log(`  With population data: ${stats.withPopulation}`);
      console.log(`  Without population data: ${stats.total - stats.withPopulation}`);
      console.log('  By type:');
      Object.entries(stats.byType).forEach(([type, count]) => {
        if (count > 0) {
          console.log(`    ${type}: ${count}`);
        }
      });
    }
    
  } catch (error) {
    console.error('❌ Validation failed:', error.message);
    process.exit(1);
  }
}

validateTexasCsv();