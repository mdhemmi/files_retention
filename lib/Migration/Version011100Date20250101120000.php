<?php

declare(strict_types=1);
/**
 * SPDX-FileCopyrightText: 2025 Nextcloud GmbH and Nextcloud contributors
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

namespace OCA\Files_Retention\Migration;

use Closure;
use OCP\DB\ISchemaWrapper;
use OCP\DB\Types;
use OCP\Migration\IOutput;
use OCP\Migration\SimpleMigrationStep;

/**
 * Add action_type and move_to_path columns
 */
class Version011100Date20250101120000 extends SimpleMigrationStep {

	/**
	 * @param IOutput $output
	 * @param Closure $schemaClosure The `\Closure` returns a `ISchemaWrapper`
	 * @param array $options
	 * @return null|ISchemaWrapper
	 */
	#[\Override]
	public function changeSchema(IOutput $output, Closure $schemaClosure, array $options): ?ISchemaWrapper {
		/** @var ISchemaWrapper $schema */
		$schema = $schemaClosure();

		if ($schema->hasTable('retention')) {
			$table = $schema->getTable('retention');

			if (!$table->hasColumn('action_type')) {
				$table->addColumn('action_type', Types::INTEGER, [
					'length' => 4,
					'default' => 0,
					'notnull' => true,
				]);
			}

			if (!$table->hasColumn('move_to_path')) {
				$table->addColumn('move_to_path', Types::STRING, [
					'length' => 4000,
					'default' => null,
					'notnull' => false,
				]);
			}
		}

		return $schema;
	}
}
