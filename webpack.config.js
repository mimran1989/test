const path = require('path');
const HtmlWebpackPlugin = require('html-webpack-plugin');
const MiniCssExtractPlugin = require('mini-css-extract-plugin');

module.exports = {
	entry: {
		main: './ui/index.ts',
		grid: './ui/components/grid/grid.ts',
		queue: './ui/components/queue/queue.ts',
		data: './ui/components/data/index.ts',
	},
	module: {
		rules: [
			{
				test: /\.tsx?$/,
				use: 'ts-loader',
				exclude: /node_modules/,
			},
			{
				test: /\.css$/i,
				use: [MiniCssExtractPlugin.loader, 'css-loader'],
			},
			{
				test: /\.(ttf|eot|svg|png|jpg|gif|ico)(\?v=[0-9]\.[0-9]\.[0-9])?$/,
				loader: 'file-loader',
			},
			{
				test: /\.s[ac]ss$/i,
				use: [
					MiniCssExtractPlugin.loader,
					{ loader: 'css-loader', options: { url: false } },
					{ loader: 'sass-loader', options: { sourceMap: true } },
				],
			},
		],
	},
	resolve: {
		extensions: ['.tsx', '.ts', '.js'],
	},
	output: {
		filename: '[name]/index.js',
		path: path.resolve(__dirname, 'force-app/main/default/staticresources/Provus'),
	},
	plugins: [
		new HtmlWebpackPlugin({
			inject: true,
			chunks: ['main'],
			filename: 'main/index.html',
		}),
		new HtmlWebpackPlugin({
			inject: true,
			chunks: ['grid'],
			filename: 'grid/index.html',
		}),
		new HtmlWebpackPlugin({
			inject: true,
			chunks: ['queue'],
			filename: 'queue/index.html',
		}),
		new HtmlWebpackPlugin({
			inject: true,
			chunks: ['data'],
			filename: 'data/index.html',
		}),
		new MiniCssExtractPlugin({
			filename: '[name]/styles.css',
		}),
	],
	devtool: 'source-map',
	externals: {
		Handsontable: 'handsOnTable',
	},
};
