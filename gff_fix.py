import argparse
if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--input', required=True)
    parser.add_argument('--output', required=True)
    args = parser.parse_args()

    with open(args.input) as gff:
        with open(args.output, 'w') as out:
            for line in gff:
                if 'ID=gene-b' in line:
                    out.write(line)
                    l = line.strip().split('\t')
                    l[2] = 'transcript'
                    id = l[-1][3:13]
                    l[-1] = l[-1].replace('ID=gene-b', 'ID=transcript-b')
                    l[-1] = f'{l[-1]};Parent={id}'
                    new_line = '\t'.join(l)
                    out.write(f"{new_line}\n")
                elif 'ID=cds-':
                    l = line.strip().replace('Parent=gene-b', 'Parent=transcript-b')
                    out.write(f'{l};biotype=protein_coding\n')
                else:
                    out.write(line)  